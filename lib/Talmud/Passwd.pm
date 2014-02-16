# -*- perl -*-

# Copyright (c) 2003 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Date: 2003-Oct-20 13:06 (EDT)
# Function: 


package Talmud::Passwd;
use MIME::Base64;
use Digest::SHA1 qw(sha1 sha1_base64);

my $ITER = 13;

sub encrypt {
    my $plain = shift;
    my $salt  = shift;

    my $ver;
    my $iter;
    if( $salt ){
        ($ver, $iter, $salt, undef) = split /\$/, $salt;
    }else{
        my $text = sha1_base64($$ . time() . $ITER . rand());
        $text =~ tr|+/||d;
        $salt = substr($text, 0, 8);
        $ver  = 'T1';
        $iter = $ITER;
    }

    my $hash = $plain;
    if( $ver eq 'T1' ){
        $hash = sha1($salt . $hash . $salt) for (1 .. (1<<$ITER));
    }else{
        # ...
    }
    $hash = encode_base64($hash);
    $hash =~ tr|+/=||d;

    return join('$', $ver, $iter, $salt, $hash);
}

sub verify {
    my $plain = shift;
    my $crypt = shift;

    encrypt($plain, $crypt) eq $crypt;
}


1;
