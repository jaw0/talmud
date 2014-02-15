-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Oct-13 21:37 (EDT)
-- Function: 
--
-- $Id: ckt-fnc.sql,v 1.7 2010/01/16 05:35:15 jaw Exp $

create or replace function mi_ckt_name (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;
	v_xid		t_object;
begin
        v_xid := wire_id from mi_ckt_wire inner join mi_g_object on (mi_ckt_wire.wire_id = mi_g_object.g_obj_id)
              where circuit_id = v_oid order by created_date limit 1;

	return mi_ckt_wire_name( v_xid, v_ext );
end;' language 'plpgsql';

create or replace function mi_ckt_end_name (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;
	v_xid		t_object;
begin
	v_xid := circuit_id from mi_circuit where a_end = v_oid or z_end = v_oid;

	return mi_ckt_name( v_xid, v_ext );
end;' language 'plpgsql';

create or replace function mi_ckt_end_better (t_object) returns t_object as '
declare
	v_oid		alias for $1;
begin
	return circuit_id from mi_circuit where a_end = v_oid or z_end = v_oid;
end;' language 'plpgsql';


create or replace function mi_ckt_wire_name (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;
	v_name		varchar;
begin
	v_name := id from mi_ckt_wire where wire_id = v_oid;

	if v_ext then
	   return ''ckt: '' || v_name;
	else
	  return v_name;
	end if;
end;' language 'plpgsql';

create or replace function mi_ckt_wire_better (t_object) returns t_object as '
declare
	v_oid		alias for $1;
begin
	return circuit_id from mi_ckt_wire where wire_id = v_oid;
end;' language 'plpgsql';

