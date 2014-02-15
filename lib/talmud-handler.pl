#!/usr/local/bin/perl
# -*- perl -*-

# Copyright (c) 2003 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Date: 2003-May-03 23:22 (EDT)
# Function:
#
# $Id: talmud-handler.pl,v 1.3 2012/11/10 00:08:41 jaw Exp $


BEGIN {
    # determine lib dir to use
    for my $file (values %INC){
        next unless $file =~ m|(.*)/talmud-handler.pl|;
        push @INC, $1;
    }
}

package Talmud;
use HTML::Mason::ApacheHandler;
use Talmud::Object;
use Talmud::Session;
use Talmud::Config;
use Talmud::Passwd;
use Talmud::Search;
use Talmud::SQL;
use Talmud::Tkt_Email;

use IPDB;

use strict;

my $db;
my $sess;

my $ah;
my $ROOT;

sub init {
    my $r = shift;
    return $ah if $ah;

    my $root = $ROOT = $r->document_root();
    my @path = [root => $root];

    $ah = HTML::Mason::ApacheHandler->new
	( comp_root 		=> \@path,
	  data_dir 	 	=> '/tmp/mason',
	  default_escape_flags	=> 'h',
	  # auto_send_headers => 0,
	  );
}

sub handler {
    my $r  = shift;
    my $ah = init( $r );
    my $rv;

    return -1 if $r->method eq 'OPTIONS';

    $r->content_type( 'text/html; charset=UTF-8' );
    eval {
	my $db = db();
	$sess = fetch($r, $db);
        $rv = $ah->handle_request($r);
    };
    if( $@ ){
        my $e = $@;

        # handle error (error_log, email, etc)
	# SR::Error::sys_error( $e );
        # give user default error page
        print STDERR "[talmud handler $$] ERROR: $e\n";
        return 500;
    }
    return $rv;
}


sub root { $ROOT }
sub sess { $sess }

sub db {

    if( $db && $db->ping() ){
	$db->{AutoCommit} = 1;
	return $db;
    }

    if( $db ){
	$db->disconnect();
	$db = undef;
    }

    $db = Talmud::SQL->connect();
}

sub unescape {
    my $t = shift;

    $t =~ s/%(..)/chr hex $1/ge;
    $t;
}

package HTML::Mason::Commands;
use JSON;
# ...


1;
