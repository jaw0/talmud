# -*- perl -*-

# Copyright (c) 2003 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Date: 2003-Oct-03 23:04 (EDT)
# Function: search functions
#
# $Id: Search.pm,v 1.1 2010/01/16 05:35:10 jaw Exp $

package Talmud::Search;

my %stop = map {($_ => 1)} qw(a an and as at be by can
			      do find he i if in is it
			      my no not of on or she
			      that the them then these they this to
			      who where why you
			      );

sub wordlist {
    my $t = shift;
    my %w;

    $t =~ s/<[^>]+>/ /g;
    my @words = split /[^a-zA-Z0-9\xc0-\xff\+\/\_\-]+/,
    	lc $t;

    # Strip leading punct
    @words = grep { s/^[^a-zA-Z0-9\xc0-\xff\_\-]+//; $_ }
    	# Must be longer than one character
    	grep { length > 1 }
    	# must have an alphanumeric
    	grep { /[a-zA-Z0-9\xc0-\xff]/ }	@words;

    foreach my $w (@words){
	next if $stop{$w};
	$w{$w} ++;
    }

    %w;
}

1;
