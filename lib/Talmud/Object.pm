# -*- perl -*-

# Copyright (c) 2003 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Date: 2003-Oct-08 10:49 (EDT)
# Function: 
#
# $Id: Object.pm,v 1.8 2010/08/21 20:18:30 jaw Exp $

package Talmud;
use Talmud::Email;
use strict;

sub g_obj_next_id {
    my $db = shift;
    $db->unique();
}

sub create_object {
    my $db   = shift;
    my $typ  = shift;
    my $oid  = shift;
    my $acl  = shift;
    my $ref  = shift;
    my $user = shift;

    if( !$user && defined(&Talmud::sess) ){
        my $s = Talmud::sess();
        $user = $s->{auth}{uid};
    }

    $oid ||= g_obj_next_id($db);
    # "into x" to trick multiplex
    $db->select_scalar( "select mi_g_object__new(?, mi_g_object_type(?), ?, ?, ?) -- INTO X",
		       $oid, $typ, $user, $acl, $ref );
}

# XXX - expects to be called from within mason, what if we add an email interface?
sub touch_object {
    my $db  = shift;
    my $oid = shift;
    my $msg = shift;

    my $s = Talmud::sess();

    $db->update_hash( 'mi_g_object', {
	modified_user => $s->{auth}{uid},
    }, [ "g_obj_id" => $oid ] );

    notify_watchers( $db, $oid, $s->{auth}{uid}, $msg );
}

sub notify_watchers {
    my $db  = shift;
    my $oid = shift;
    my $mby = shift;
    my $msg = shift;

    
    # get watchers
    my $user = $db->select_all(<<ESQLA, $oid);
select email, nickname
  from mi_user
    inner join mi_party on(user_id = party_id)
    inner join mi_g_obj_rel on(obj_a = user_id)
  where notifyme_p
    and obj_b = ? and rel_type_name = 'bkmk/attach'
ESQLA
    ;

    return unless @$user;

    # about the user doing the update
    my $m = $db->select_1hashref(<<ESQLM, $mby);
select nickname
  from mi_user
  where user_id = ?
ESQLM
    ;

    # about the object being updated
    my $d = $db->select_1hashref(<<ESQLB, $oid);
select mi_object_name( mi_object_best(g_obj_id), true )  AS name,
    mi_object_fullurl( mi_object_best(g_obj_id) )        AS url
  from mi_g_object
  where g_obj_id = ?
ESQLB
    ;
;

    # send email
    for my $user (@$user){
        _send_notify( $user, $msg, $oid, $m, $d );
    }
}

sub _send_notify {
    my $user  = shift;
    my $msg   = shift;
    my $oid   = shift;
    my $md    = shift;
    my $od    = shift;

    print STDERR "notifying: $user->{email}\n";

    my $head = {
        To	=> $user->{email},
        From	=> 'nobody',
        Subject	=> "$md->{nickname} updated $od->{name}",
    };
    my $body = "\n$md->{nickname} updated $od->{name}\n";
    $body .= "\thttp://$ENV{SERVER_NAME}/$od->{url}\n";
    $body .= "\n$msg\n" if $msg;

    Talmud::Email::send_email( $head, $body );
}

1;
