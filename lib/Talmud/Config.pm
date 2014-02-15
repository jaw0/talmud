# -*- perl -*-

# Copyright (c) 2003 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Created: 2003-Nov-12 11:39 (EST)
# Function: fetch and cache global config from db
#
# $Id: Config.pm,v 1.5 2010/01/16 03:21:48 jaw Exp $

package Talmud;

my $config;
my $when;

sub config {
    my $now = time();

    if( $now - $when > 300 ){
	# update config

	$db = Talmud::db();
	$config = { $db->select_2columns('select param, value from mi_sys_config where value is not null') };
	$when = $now;
    }

    return $config;
}

1;
