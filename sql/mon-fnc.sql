-- Copyright (c) 2004 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Created: 2004-Jan-08 16:54 (EST)
-- Function: argus monitoring
--
-- $Id: mon-fnc.sql,v 1.1 2006/07/15 22:02:45 jaw Exp $

create or replace function mon_user_name (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;
begin
	v_name		varchar;
begin
	select into v_name coalesce(realname, email) from mon_user
	       where user_id = v_oid;

	if v_ext then
	    return ''user: '' || v_name;
	else
	    return v_name;
        end if;
end;' language 'plpgsql';

create or replace function monitor_name (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;
begin
	return hostname || ''_'' || service from monitor where mon_id = v_oid;
end;' language 'plpgsql';

