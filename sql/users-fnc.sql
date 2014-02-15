-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Sep-26 12:05 (EDT)
-- Function: 
--
-- $Id: users-fnc.sql,v 1.6 2010/01/15 18:13:24 jaw Exp $

-- to create new groups
create or replace function mi_group__new (varchar, varchar) returns t_object as '
declare
	n_name		alias for $1;
	n_descr		alias for $2;

	v_gid		t_object;
begin
	select into v_gid mi_g_object__new_type( ''users/group'' );
	insert into mi_party (party_id) values (v_gid);
	insert into mi_group (group_id, groupname, descr) values (v_gid, n_name, n_descr);

	return v_gid;
end;' language 'plpgsql';

-- to add root user to groups
create or replace function mi_add_user_to_group (t_object, varchar) returns integer as '
declare
	n_uid		 alias for $1;
	n_group		 alias for $2;
begin
	insert into mi_party_group (party_id, group_id) values (n_uid,
	       (select group_id from mi_group where groupname = n_group));

	return 1;
end;' language 'plpgsql';

-- name functions
create or replace function mi_party_name (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;
begin
	return email from mi_party where party_id = v_oid;
end;' language 'plpgsql';

create or replace function mi_person_name (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;
begin
	return coalesce (realname, email) from mi_person, mi_party
	       where person_id = v_oid and party_id = v_oid;
end;' language 'plpgsql';



create or replace function mi_user_name (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;
	v_name		varchar;
begin
	select into v_name coalesce (nickname, realname, email) from mi_user, mi_person, mi_party
	       where user_id = v_oid and person_id = v_oid and party_id = v_oid;

	if v_ext then
	    return ''user: '' || v_name;
	else
	    return v_name;
        end if;
end;' language 'plpgsql';

create or replace function mi_group_name (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;
	v_name		varchar;
begin
	select into v_name groupname from mi_group where group_id = v_oid;
	if v_ext then
	    return ''group: '' || v_name;
	else
	    return v_name;
	end if;
end;' language 'plpgsql';


