# -*- perl -*-

# Copyright (c) 2003 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Date: 2003-Oct-24 09:34 (EDT)
# Function: 
#
# $Id: SQL.pm,v 1.10 2010/08/21 20:18:30 jaw Exp $

package Talmud::SQL;
use DBI;
use Socket;
use MIME::Base64;
use Sys::Hostname;
use POSIX;
use strict;
use vars qw($SQLVERBOSE @ISA);
use vars qw($DBDSN $DBUSER $DBPASS %DBARGS);
require "t_conf.pl";

@ISA = qw(DBI);
$SQLVERBOSE = 0;

sub connect {
    my $class = shift;


    my $dbh = $class->SUPER::connect( $DBDSN, $DBUSER, $DBPASS, {
        AutoCommit => 1,
        PrintError => 0,
        RaiseError => 1,
        %DBARGS,
    } );

    verbose( "connected to database" );

    $dbh;
}

sub verbose {
    my $st  = shift;

    return unless $SQLVERBOSE;

    my($tag, $nc);
    while(1){
        my @c = caller( $nc++ );
        $tag = "$c[1]:$c[2]";           # file:line
	$tag =~ s/.*talmud\///;
        last if $c[0] ne 'Talmud::SQL::db'; # pkg
        last if $nc > 10;
    }
    
    $tag = " $$ [$tag]";

    $st =~ s/^/SQL>>$tag /gm;
    print STDERR "$st\n";
    print STDERR "  ", join(' | ', @_), "\n" if @_;
}

my $uniq_n = int rand(256);
sub unique {
    my( $ip, $u );
    
    $ip = gethostbyname( hostname() );
    $u  = encode_base64( pack('nna4N', $$, $uniq_n++, $ip, time()) );
    $u  =~ s/[\r\n]*$//;
    $u  =~ s/=*$//;
    $u  =~ tr%+=/%_.-%;

    $u;

}


################################################################

package Talmud::SQL::db;
use vars '@ISA';
@ISA = qw(DBI::db);

sub disconnect {
    my $dbh = shift;

    Talmud::SQL::verbose( "disconnected from database" );
    $dbh->SUPER::disconnect;
}

sub unique {
    Talmud::SQL::unique();
}

sub start {
    my $dbh = shift;
    $dbh->{AutoCommit} = 0;
}

sub commit {
    my $dbh = shift;

    $dbh->SUPER::commit();
    $dbh->{AutoCommit} = 1;
}
sub rollback {
    my $dbh = shift;

    $dbh->SUPER::rollback();
    $dbh->{AutoCommit} = 1;
}

sub do {
    my $dbh  = shift;
    my $stmt = shift;
    my $sth;

    eval {
        Talmud::SQL::verbose( $stmt, @_ );
	$sth = $dbh->prepare( $stmt );
	$sth->execute( @_ );
    };
    if( $@ ){
        Talmud::SQL::verbose( $@ );
	die $@;
    }
    
    $sth;
}

sub select_scalar {
    my $dbh  = shift;
    my $stmt = shift;

    my $st = $dbh->do( $stmt, @_ );
    my $a = scalar $st->fetchrow_array();
    $st->finish();
    $a;
}

sub select_1hashref {
    my $dbh  = shift;
    my $stmt = shift;

    my $st = $dbh->do( $stmt, @_ );
    my $a = $st->fetchrow_hashref();
    $st->finish();
    $a;
}

sub select_1array {
    my $dbh  = shift;
    my $stmt = shift;

    my $st = $dbh->do( $stmt, @_ );
    my @a = $st->fetchrow_array();
    $st->finish();
    @a;
}

sub select_column {
    my $dbh  = shift;
    my $stmt = shift;

    my $st = $dbh->do( $stmt, @_ );
    map { $_->[0] }  @{ $st->fetchall_arrayref() };
}
*select_1column = \&select_column;

sub select_2columns {
    my $dbh  = shift;
    my $stmt = shift;

    my $st = $dbh->do( $stmt, @_ );
    map { ( $_->[0] => $_->[1] ) }  @{ $st->fetchall_arrayref() };
}

sub select_all {
    my $dbh  = shift;
    my $stmt = shift;

    my $st = $dbh->do( $stmt, @_ );
    my @rows;
    while( my $r = $st->fetchrow_hashref() ){ push @rows, $r }
    \@rows;
}

sub insert_hash {
    my $dbh = shift;
    my $tbl = shift;
    my $iv  = shift;
    my( $sql, @c, @v, @q );
    
    foreach my $k (sort keys %$iv){
	my $v = $iv->{$k};
	# next unless defined $v;
	push @c, $k;

	if( ref $v eq 'SCALAR' ){
	    push @q, $$v;
	}elsif( ref $v eq 'HASH' ){
	    # QQQ ...
	}else{
	    push @v, $v;
	    push @q, '?';
	}
    }
    
    $sql = "INSERT INTO $tbl \n\t(" . join(', ', @c) .
	")\nVALUES\n\t(" . join(', ', @q) . ')';
    
    $dbh->do( $sql, @v );
}

sub where {
    my $wh = shift;
    
    my @wh = @$wh;
    my ($w, @v);
    while ( @wh ){
        my $c = shift @wh;
        my $v = shift @wh;
        my $cnd = "$c = ?";

        if( ref $v ){
            my $op = $v->{op};
            $v = $v->{val};
            $cnd = "$c $op ?";
        }
        
        $w = $w ? "$w AND $cnd" : $cnd;
        push @v, $v;
    }
    return ($w, @v);
}

sub update_hash {
    my $dbh = shift;
    my $tbl = shift;
    my $iv  = shift;
    my $wh  = shift;
    my( $sql, @c, @v );

    $sql = "UPDATE $tbl SET ";
    foreach my $k (sort keys %$iv){
	my $v = $iv->{$k};
	# next unless defined $v;

	if( ref $v eq 'SCALAR' ){
	    push @c, "$k = $$v";
	}elsif( ref $v eq 'HASH' ){
	    # QQQ ...
	}else{
	    push @c, "$k = ?";
	    push @v, $v;
	}
    }
    $sql .= join(', ', @c);

    my( $w, @w ) = where( $wh );
    
    $dbh->do( "$sql WHERE $w", @v, @w );
}

sub row {
    my $dbh = shift;
    my $tbl = shift;
    my $wh  = shift;

    my($w,@v) = where($wh);
    my $sql = "select * from $tbl where $w";

    $dbh->select_1hashref($sql, @v);
}

sub error_sanitize {
    my $dbh = shift;
    my $msg = shift;

    if( $msg =~ /at .* line/ ){
        $msg =~ s,at /.*/([^/]+).pl,at $1,;
    }

    $msg =~ s/^.*execute failed:\s*//;
    $msg =~ s/at sqlutil.*//;
    $msg =~ s/ERROR:\s+//;
    $msg =~ s/\s*Stack:.*//s;
    $msg;
}

package Talmud::SQL::st;
use vars '@ISA';
@ISA = qw(DBI::st);




1;

