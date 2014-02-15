#!/usr/local/bin/perl
# -*- perl -*-

# Copyright (c) 2003 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Date: 2003-Oct-11 10:35 (EDT)
# Function: process incoming mail
#
# $Id: mail-handler.pl,v 1.10 2010/01/18 03:15:26 jaw Exp $

# read email on stdin, insert into db
# not quite RFC compliant...

use lib '/home/athena/jaw/projects/talmud/lib';
use Talmud::SQL;
use Talmud::Object;
use MIME::Parser;
use Getopt::Std;

my %opt;
getopts('s:', \%opt);
# -s section-tag
use strict;

my $m = read_message();
process_headers($m);
check_message($m);

my $db = Talmud::SQL->connect();

eval {
    $db->start();
    insert_db($db, $m);
    # send_mail( $m );
    $db->commit();
};
if( $@ ){
    $db->rollback();
    die $@;
}

sub read_message {

    my $parser = new MIME::Parser;
    $parser->extract_nested_messages(0);
    $parser->output_to_core(1);

    my $entity;
    # do not trap exptions in read - let it die
    $entity = $parser->parse(\*STDIN);
    die "could not read message\n" unless $entity;

    $entity->make_multipart();
    my $head = $entity->head();
    $head->unfold();

    return { e => $entity };
}


sub process_headers {
    my $m = shift;
    my $h = $m->{e}->head();

    # subject
    my $s = $h->get('Subject');
    if( $s ){
	if( $s =~ /\[(\S+)\s+\#(\d+)\](.*)/ ){
	    $m->{tag} = $1;
	    $m->{tkt} = $2;
	    $s = $3;
	};
	$s =~ s/Re:\s+//i;
	$s =~ s/^\s*//;
	$s =~ s/\s*$//;
	$m->{subject} = $s;
    }

    # from
    my $f = $h->get('Reply-To') || $h->get('From') || $h->get('Sender');
    if( $f ){
	$f =~ s/\([^\)]+\)//g;
	$f =~ s/\"[^\"]+\"//g;
	if( $f =~ /<([^>]+)>/ ){
	    $f = $1;
	}

	$m->{from} = $f;
    }
}

sub check_message {
    my $m = shift;
    my $h = $m->{e}->head();

    die "Loop detected\n" if $h->get('X-Tkt-Info');
}

sub insert_db {
    my $db = shift;
    my $m = shift;
    my $e = $m->{e};
    my( $tid, $sec, $cr, $action );


    # find or create tkt_user
    my $userid = find_or_create_person($m->{from});

    $action = 'update';
    if( $m->{tkt} ){
	# update
	# find tkt_id from number
        $tid = $db->select_scalar('select tkt_id from mi_ticket where tkt_number = ?', $m->{tkt});
    }
    if( $m->{tag} ){
	# verify it is a valid tag
        $sec = $db->select_scalar('select section_id from mi_tkt_section where tag = ?', $m->{tag});
    }
    if( !$tid || !$sec ){
	# create new tkt

	$action = 'create';

	$sec = $db->select_scalar("select section_id from mi_tkt_section where tag = ?", $opt{s});

	$sec = $db->select_scalar("select section_id from mi_tkt_section where tag = 'UNK'" )
	    unless $sec;

        $db->do('lock table mi_ticket in exclusive mode');
        my $tktno = $db->select_scalar('select MAX(tkt_number) from mi_ticket') || 1000;
        $tktno ++;

	# create tkt
        $tid = Talmud::g_obj_next_id($db);
	Talmud::create_object($db, 'tkt/ticket', $tid, undef, $sec, $userid);

        $db->insert_hash('mi_task', {
            task_id	=> $tid,
            summary	=> $m->{subject},
            });

        $db->insert_hash('mi_ticket', {
            tkt_id	=> $tid,
            tkt_number	=> $tktno,
            creator	=> $userid,
        });

	print STDERR "created tkt $tid\n";
    }

    $m->{action} = $action;
    $m->{tag}    = $db->select_scalar("select tag from mi_tkt_section where section_id = ?", $sec);
    $m->{tkt}    = $db->select_scalar("select tkt_number from mi_ticket where tkt_id = ?",   $tid);

    # create event
    my $eid = Talmud::create_object($db, 'tkt/event', undef, undef, undef, $userid);

    $db->insert_hash( 'mi_tkt_event', {
        event_id	=> $eid,
        tkt_id		=> $tid,
        event_who	=> $userid,
        action		=> 'create',
    } );


    # stick headers in db
    my $hdr = $e->stringify_header();
    insert_content($db, $eid, $cr, '', $hdr, 'text/rfc822-headers');

    my $type = $e->effective_type();
    my @p;

    if( $type =~ /alternative/ ){
	# pick one msg
	my @m = $e->parts();
	my @h;

	foreach my $p (@m){
	    if( $p->effective_type =~ m,text/plain, ){
		push @p, $p;
		last;
	    }
	    if( $p->effective_type =~ m,text/html, ){
		push @h, $p;
	    }
	}

	# no text/plain - try html
	@p = shift @h unless @p;

	# still nothing, use all parts, pretend mixed
	@p = $e->parts() unless @p;

    }else{
	# insert all parts
	@p = $e->parts();
    }

    foreach my $p (@p){
	my $type = $p->effective_type();
	$type =~ s/\;.*//;

	# QQQ - should we delete certain types of content?

	my $d = $p->bodyhandle->as_string;
	my $s = $p->head->recommended_filename();
	die "Message too large\n" if length($d) > 500000;
	insert_content($db, $eid, $cr, $s || $m->{subject}, $d, $type );
    }
}

sub insert_content {
    my $db   = shift;
    my $eid  = shift;
    my $user = shift;
    my $sum  = shift;
    my $cont = shift;
    my $type = shift;

    my $cid = Talmud::g_obj_next_id($db);

    Talmud::create_object($db, 'tkt/content', $cid, 'r; r', $eid, $user);

    $db->insert_hash('mi_content', {
        content_id  	=> $cid,
        content_type	=> 'tkt',
        mime_type    	=> $type,
    } );

    my $vid = Talmud::create_object($db, 'generic/version', undef, undef, undef, $user),

    # content may be binary, do it the hard way
    my $s = $db->prepare("insert into mi_content_version (content_id, version_id, content) values (?, ?, ?)");
    $s->bind_param(1, $cid);
    $s->bind_param(2, $vid);
    $s->bind_param(3, $cont, { pg_type => DBD::Pg::PG_BYTEA() } );
    $s->execute();
}

sub find_or_create_person {
    my $from = shift;

    my $id = $db->select_scalar('select party_id from mi_party where email = ?', $from);

    unless($id){
        $id = Talmud::create_object($db, 'users/person', undef, undef, undef, undef);
        $db->insert_hash('mi_party', {
            party_id	=> $id,
            email	=> $from,
        });
        $db->insert_hash('mi_person', {
            person_id	=> $id,
            realname	=> $from,
            category	=> 'tktemail',
        });
    }

    return $id;
}

