# -*- perl -*-

# Copyright (c) 2003 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Date: 2003-Oct-09 13:52 (EDT)
# Function: handle email <-> ticket interface
#
# $Id: Tkt_Email.pm,v 1.1 2010/08/21 20:18:47 jaw Exp $

package Talmud::Tkt_Email;
use Talmud::Email;
use strict;

# ticket was updated - send email
sub updated {
    my $db   = shift;	# ro
    my $oid  = shift;
    my %args = @_;
    my(  @rcpt );
    my $s = Talmud::sess();

    # get list of email addrs
    if( $args{tello} ){

	# get email creator
	my $o = $db->select_scalar(
	       "select email from mi_party inner join mi_ticket on (mi_ticket.creator = mi_party.party_id)".
	       "  where tkt_id = ?", $oid );

	push @rcpt, $o if $o;
    }

    if( $args{tellw} ){

	# get list of workers
	push @rcpt, $db->select_column(
	"select email from mi_ticket inner join mi_task on (tkt_id = task_id), mi_party".
	"    where tkt_id = ?".
	"      and ( creator = party_id or owner = party_id )", $oid );

	push @rcpt, $db->select_column(
	"select email from mi_tkt_event, mi_party".
	"  where tkt_id = ? ".
	"    and ( event_who = party_id or owner = party_id )", $oid );

    }

    # uniq + remove self
    my %r = map {($_ => 1)} @rcpt;
    delete $r{ $s->{auth}{uid} };
    @rcpt = keys %r;

    # print STDERR join( ' ', %args ), "\n";
    print STDERR "rcpts: @rcpt\n";

    # compose email
    my $who   = $s->{auth}{user};
    my $tktno = $db->select_scalar("select tkt_number from mi_ticket where tkt_id = ?", $oid );

    my( $tag, $from ) = $db->select_1array("select tag, mail_from from mi_tkt_section inner join ".
					   " mi_g_object on (g_obj_id = refers_to) where g_obj_id = ?", $oid );

    my $body = <<EOB;
ticket #$tktno has been updated by $who

$args{details}

$args{content}

EOB
    ;

    # print STDERR "body: $body\n";

    # send message

    foreach my $rcpt ( @rcpt ){
        my $head = {
            To			=> $rcpt,
            Subject		=> "[$tag #$tktno] Re: $args{subject}",
            From		=> $from,
            'Reply-To'		=> $from,
            'X-Tkt-Info'	=> "$oid/$args{event}",
        };
        Talmud::Email::send_email( $head, $body );
    }

}


1;
