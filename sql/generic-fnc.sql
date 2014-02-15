-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Sep-26 11:42 (EDT)
-- Function: 
--
-- $Id: generic-fnc.sql,v 1.7 2010/01/18 03:15:30 jaw Exp $

-- virtual functions
create or replace function mi_content_name (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;	-- not used

        v_title		varchar;
begin
	v_title := summary from mi_content_version
	       where content_id = v_oid and current_version_p;

        if v_title is null OR v_title = '''' then
            v_title := ''(untitled)'';
        end if;

        return v_title;
end;' language 'plpgsql';

create or replace function mi_content_version_name (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;	-- not used
begin
	return ''v('' || summary || '')'' from mi_content_version where version_id = v_oid;
end;' language 'plpgsql';

create or replace function mi_content_version_better (t_object) returns t_object as '
declare
	v_oid		alias for $1;
begin
	return content_id from mi_content_version where version_id = v_oid;
end;' language 'plpgsql';


----------------------------------------------------------------
-- trigger to maintain current_version_p flag
----------------------------------------------------------------
create or replace function mi_content_version_insert () returns opaque as '
declare
	v_cont	    t_object;
begin
	v_cont := NEW.content_id;

	update mi_content_version set current_version_p = false
	   where content_id = v_cont;

	NEW.current_version_p := true;

	return NEW;
end;' language 'plpgsql';

create trigger mi_content_version_insert_tr before insert on mi_content_version for each row 
  execute procedure mi_content_version_insert ();

