# -*- perl -*-

# Copyright (c) 2003 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Date: 2003-Apr-30 14:15 (EDT)
# Function:
#
# $Id: Session.pm,v 1.5 2010/08/21 20:18:30 jaw Exp $

package Talmud;

my $COOKIENAME = 'session';

sub cookiename { $COOKIENAME }

sub new_cookie {
    my( $c, $buf, $v, $x );
    my @set = ('A'..'Z', 'a'..'z', '0'..'9', '_', '.');		# length = 64
    # split('', '.:,/+=-_%@'));

    open( DEVRND, "/dev/urandom" );
    foreach (1..64){
        sysread( DEVRND, $buf, 1 );
        $v = ord($buf);
        $x ^= ($v & ~63) >> (rand(7)+1);
        $c .= $set[ ($x ^ $v) & 63 ];
    }
    close DEVRND;
    $c;
}

sub new_salt {
    my( $c, $buf );
    my @set = ('A'..'Z', 'a'..'z', '0'..'9');
    $c .= $set[ rand(@set) ];
    $c .= $set[ rand(@set) ];
    $c;
}

sub fetch {
    my $r  = shift;
    my $db = shift;
    my $q = CGI->new('');	# because Mason already has them

    my $c = $q->cookie( $COOKIENAME );
    print STDERR "fetch: $c\n";

    my $me = {
	r    => $r,
	q    => $q,
	ci   => $c,
    };
    bless $me;

    $me->validate($db);
    $me;
}

# RSN - cache cookie => auth
sub validate {
    my $me = shift;
    my $db = shift;
    my( $stmt, $sth );

    return unless $me->{ci};
    return if $me->{ci} eq 'invalid';

    print STDERR "got cookie: $me->{ci}\n";

    $stmt = <<ESQL;
SELECT user_id, coalesce(nickname, realname), theme, section_id
  FROM mi_web_cookie INNER JOIN mi_site_user USING (user_id)
  WHERE cookie_id = ?
    AND server = ?
    AND status = 'active'
    AND expires > now()
ESQL
    ;

    my($uid, $user, $theme, $sect) = $db->select_1array($stmt, $me->{ci}, $ENV{SERVER_NAME} );

    # invalid, forged, or expired cookie?
    if( !$uid ){
        $me->{ci} = '';
        return;
    }

    # get groups
    $stmt = <<ESQL;
SELECT groupname FROM mi_group INNER JOIN mi_user_group USING (group_id)
  WHERE user_id = ?
ESQL
    ;

    $sth = $db->do($stmt, $uid);
    my @grps = @{$sth->fetchall_arrayref()};
    @grps = map { $_->[0] } @grps;
    push @grps, 'user', 'loggedin';

    print STDERR "auth: $uid, @grps\n";

    $me->{auth} = {
	user   => $user,
	uid    => $uid,
	groups => { map {($_ => 1)} @grps },
	pref   => { theme => $theme, section => $sect, },
    };

}

sub pretty_age {
    my $sec = shift;

    if( $sec < 120 ){
	return sprintf "%d sec", $sec;
    }
    $sec /= 60;
    if( $sec < 120 ){
	return sprintf "%d min", $sec;
    }
    $sec /= 60;
    if( $sec < 48 ){
	return sprintf "%d hrs", $sec;
    }
    $sec /= 24;

    if( $sec < 60 ){
	return sprintf "%d days", $sec;
    }

    $sec /= 28;  # months

    sprintf "%d mon", $sec;

}


1;
