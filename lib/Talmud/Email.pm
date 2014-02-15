# -*- perl -*-

# Copyright (c) 2010 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Created: 2010-Aug-21 12:39 (EDT)
# Function: send email
#
# $Id: Email.pm,v 1.1 2010/08/21 20:18:30 jaw Exp $

package Talmud::Email;
use strict;

my @SENDMAIL = qw{env PATH=/usr/lib:/usr/sbin sendmail};

sub send_email {
    my $head = shift;
    my $body = shift;

    my @cmd = (@SENDMAIL, '-t');
    push @cmd, '-f', $head->{_sender} if $head->{_sender};
    open( MAIL, '|-', @cmd ) || die "cannot send mail: $!\n";

    # headers
    for my $k (keys %$head){
        next if $k =~ /^_/;
        print MAIL "$k: $head->{$k}\n";
    }

    print MAIL "\n";
    print MAIL $body;
    close MAIL;

}

1;
