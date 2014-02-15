#!/usr/local/bin/perl
# -*- perl -*-

# Copyright (c) 2003 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Created: 2003-Nov-07 15:02 (EST)
# Function: check and clean objects in db
#
# $Id: dbck.pl,v 1.4 2010/08/29 15:16:24 jaw Exp $

use lib('/home/athena/jaw/projects/talmud/lib');
use Talmud::SQL;
require 't_conf.pl';


my $db = Talmud::SQL->connect();
$db->start();

$stmt = <<EOSQL;
select g_obj_id, g_obj_table_name, g_obj_pk_name
    from mi_g_object inner join mi_g_object_type using (g_obj_type)
    order by g_obj_id
EOSQL
    ;

my $s = $db->do($stmt);

my $rows = 0;
my $orph = 0;

while( my $r = $s->fetchrow_arrayref() ){
    my($id, $tbl, $pk) = @$r;

    $rows ++;
    next unless $tbl;
    
    my $n = $db->select_scalar("select count(*) from $tbl where $pk = ?", $id);
    unless($n){
	$orph ++;
	print STDERR "orphan object $id ($tbl)\n";
	$db->do('delete from mi_g_object where g_obj_id = ?', $id);
    }
}

$db->commit();
$db->do('vacuum full analyze') if $orph;

print STDERR "examined $rows objects\nremoved $orph orphans\n";
