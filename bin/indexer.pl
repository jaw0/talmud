#!/usr/local/bin/perl
# -*- perl -*-

# Copyright (c) 2003 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Date: 2003-Oct-03 19:32 (EDT)
# Function: insert content into index
#
# $Id: indexer.pl,v 1.11 2010/01/16 05:35:09 jaw Exp $

use lib('/home/athena/jaw/projects/talmud/lib');

use strict;
use Search;
use Talmud::SQL;

my $db = Talmud::SQL->connect();
$db->start();

# get last run timestamp
my $t = $db->select_scalar("select coalesce(modified_date, created_date) from mi_g_object where g_obj_type = ".
			  "mi_g_object_type('search/object')");
print STDERR "last index run: $t\n";

# $t = '2003-01-01';

eval {

    # update content
    my $stmt =<<EOS;
select content_id, content, summary
  from mi_content_version inner join mi_g_object on (version_id = g_obj_id)
    inner join mi_content using (content_id)
  where current_version_p and created_date > ?
    and searchable_p
    and substr(mime_type, 1, 5) = 'text/'
EOS
    ;

    my $st = $db->do($stmt, $t);

    while( my $r = $st->fetchrow_arrayref() ){
	my( $id, $cont, $sum ) = @$r;
	print STDERR "got $id, $sum\n";

	update_index( $db, $id, $cont, $sum );
    }


    # add people
    $stmt =<<EOS;
select person_id, realname
  from mi_person inner join mi_g_object on (person_id = g_obj_id)
  where coalesce(modified_date, created_date) > ?
EOS
    ;
    $st = $db->do( $stmt, $t );

    while( my $r = $st->fetchrow_arrayref() ){
	my( $id, $name ) = @$r;

	# also add in contact data values
	my @data = $db->select_column("select value from mi_contact_data where contact_id = ?", $id);

	update_index( $db, $id, $name, join(' ', @data) );
    }

    # add eqmt
    $stmt =<<EOS;
select eqmt_id, fqdn
  from mi_eqmt inner join mi_g_object on (eqmt_id = g_obj_id)
  where coalesce(modified_date, created_date) > ?
EOS
    ;

    $st = $db->do($stmt, $t);

    while( my $r = $st->fetchrow_arrayref() ){
	my( $id, $fqdn ) = @$r;

	update_index( $db, $id, $fqdn, '');
    }

    # add task/tkt subjects
    $stmt =<<EOS;
select task_id, summary
  from mi_task inner join mi_g_object on (task_id = g_obj_id)
  where coalesce(modified_date, created_date) > ?
EOS
    ;

    $st = $db->do($stmt, $t);

    while( my $r = $st->fetchrow_arrayref() ){
	my( $id, $sub ) = @$r;

	update_index( $db, $id, $sub, '');
    }

    # add ckt ids
    $stmt =<<EOS;
select wire_id, id
  from mi_ckt_wire inner join mi_g_object on (circuit_id = mi_g_object.g_obj_id)
  where coalesce(modified_date, created_date) > ?
EOS
    ;

    $st = $db->do($stmt, $t);

    while( my $r = $st->fetchrow_arrayref() ){
	my( $cid, $id ) = @$r;
	# break id into pieces, and index each piece
	my @p = $id =~ /(\d+)/g;
	push @p, $id =~ /(\D+)/g;
	update_index( $db, $cid, $id, join(' ', @p) );
    }

    # ipdb - meta data
    $stmt = <<EOS;
select meta_id, netname
  from mi_ipdb_meta inner join mi_g_object on (meta_id = mi_g_object.g_obj_id)
  where coalesce(modified_date, created_date) > ?
EOS
    ;
    $st = $db->do($stmt, $t);

    while( my $r = $st->fetchrow_arrayref() ){
	my( $id, $nm ) = @$r;
	update_index( $db, $id, $nm, '' );
    }

    # ipdb blocks - RSN cust info
    $stmt = <<EOS;
select block_id, swip_id, descr
  from mi_ipdb_block inner join mi_g_object on (block_id = mi_g_object.g_obj_id)
  where coalesce(modified_date, created_date) > ?
EOS
    ;
    $st = $db->do($stmt, $t);

    while( my $r = $st->fetchrow_arrayref() ){
	my( $id, $sw, $dsc ) = @$r;
	update_index( $db, $id, $sw, $dsc );
    }


    # RSN - add other data




    # update timestamp
    $db->do("update mi_g_object set modified_date = now() where g_obj_type = ".
	    "mi_g_object_type('search/object')");

    $db->commit();
};

if( $@ ){
    my $emsg = $@;
    $db->rollback();
    die "$emsg\n";
}

$db->disconnect( );


sub update_index {
    my $db = shift;
    my $id = shift;
    my $wa = shift;
    my $wb = shift;

    # drop old content
    $db->do("delete from mi_search_index where object = ?", $id );

    my %words = Talmud::Search::wordlist( "$wa $wb" );

    foreach my $w (keys %words){
	print STDERR "  word $w: ", $words{$w}, "\n";
	# NB: do caches the prepared statement...
	$db->do("insert into mi_search_index (object, score, word) values (?, ?, ?)",
		$id, $words{$w}, $w );
    }

}


