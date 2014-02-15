# -*- perl -*-

# Copyright (c) 2003 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Date: 2003-Oct-20 13:06 (EDT)
# Function: 
#
# $Id: Passwd.pm,v 1.2 2010/01/16 03:21:48 jaw Exp $

package Talmud::Passwd;

use Digest::MD5 ('md5_base64');

sub encrypt {
    my $plain = shift;
    
    md5_base64($plain);
}

sub verify {
    my $plain = shift;
    my $crypt = shift;

    encrypt($plain) eq $crypt;
}

1;
