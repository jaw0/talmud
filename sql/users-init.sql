-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Sep-26 12:02 (EDT)
-- Function: 
--
-- $Id: users-init.sql,v 1.5 2010/01/15 18:13:24 jaw Exp $

select mi_g_object_type__new( 'users/party',
			   'users/view-party',
			   'mi_party',
			   'party_id',
			   'mi_party_name',
			   NULL,
			   NULL );

select mi_g_object_type__new( 'users/person',
			   'contacts/view-contact',
			   'mi_person',
			   'person_id',
			   'mi_person_name',
			   NULL,
			   mi_g_object_type('users/party') );

select mi_g_object_type__new( 'users/user',
			   'users/view-user',
			   'mi_user',
			   'user_id',
			   'mi_user_name',
			   NULL,
			   mi_g_object_type('users/person') );

select mi_g_object_type__new( 'users/group',
			   'users/view-group',
			   'mi_group',
			   'group_id',
			   'mi_group_name',
			   NULL,
			   mi_g_object_type('users/party') );

insert into mi_person_category values ('staff');
insert into mi_person_category values ('vendor');
insert into mi_person_category values ('telco');
insert into mi_person_category values ('jrandom');

select mi_group__new ( 'root',      'nothing interesting' );
select mi_group__new ( 'secadmin',  'secure administrator' );
select mi_group__new ( 'acctadmin', 'account administrator' );
select mi_group__new ( 'secoper',   'security operator' );
select mi_group__new ( 'audit',     'auditor' );
select mi_group__new ( 'staff',     'staff' );


-- create root user
create function tmp_0 () returns integer as '
declare
	v_uid		t_object;
	v_groot		t_object;
begin

	select into v_uid mi_g_object__new_type(''users/user'');
	insert into mi_party (party_id) values (v_uid);
	insert into mi_person (person_id, realname, category) values (v_uid, ''Super User'', ''staff'');
	insert into mi_user (user_id, nickname, passwd)
	  -- passwd = toor
	  values (v_uid, ''root'', ''eySvyLyA5UjWbE5/9yFxxQ'');
	update mi_g_object set created_user = v_uid where g_obj_id = v_uid;

	update mi_user set photo_url = ''http://www.example.com/~jaw/metrop-rotwang.jpg'',
	    url = ''http://www.example.com'',
	    biography = ''I am the first user. I am the last user. I am the alpha, and I am the omega. I own this system and I read your email.''
	    where user_id = v_uid;

	-- set group membership
	perform	mi_add_user_to_group(v_uid, ''root'');
	perform	mi_add_user_to_group(v_uid, ''secadmin'');
	perform	mi_add_user_to_group(v_uid, ''acctadmin'');

	return 1;

end;' language 'plpgsql';

select tmp_0();
drop function tmp_0();

