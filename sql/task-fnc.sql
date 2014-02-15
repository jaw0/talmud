-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Created: 2003-Nov-10 12:59 (EST)
-- Function: 
--
-- $Id: task-fnc.sql,v 1.2 2010/01/15 18:13:22 jaw Exp $

create or replace function mi_task_name (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;	-- not used
begin
	return summary from mi_task where task_id = v_oid;
end;' language 'plpgsql';


-- determine if an object is a task
create or replace function mi_isa_task (t_object) returns bool as '
declare
    v_oid	    alias for $1;
begin
    return mi_object_isa( v_oid, mi_g_object_type(''generic/task'') );
end;' language 'plpgsql';

