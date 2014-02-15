-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Oct-05 15:01 (EDT)
-- Function: 
--
-- $Id: eqmt-fnc.sql,v 1.6 2010/08/21 20:18:31 jaw Exp $

create or replace function mi_facility_name (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;	-- not used
begin
	return code from mi_facility where fac_id = v_oid;
end;' language 'plpgsql';

create or replace function mi_eqmt_name (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;	-- not used
begin
	return fqdn from mi_eqmt where eqmt_id = v_oid;
end;' language 'plpgsql';

create or replace function mi_iface_name (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;	-- not used
	v_enm		t_object;
begin
	v_enm := fqdn || ''/'' iface_name from mi_eqmt inner join mi_interface using (eqmt_id) where iface_id = v_oid;

	return v_enm;
end;' language 'plpgsql';

-- some helper functions

create or replace function mi_fac_type__new (varchar) returns integer as '
declare
	n_name		alias for $1;
begin
	insert into mi_fac_type (name) values (n_name);
	return 1;
end;' language 'plpgsql';

create or replace function mi_hw_type__new (varchar, varchar) returns integer as '
declare
	n_abbr		alias for $1;
	n_name		alias for $2;
begin
	insert into mi_hw_type (hw_type_id, name) values (n_abbr, n_name);
	return 1;
end;' language 'plpgsql';

create or replace function mi_manufacturer__new (varchar) returns integer as '
declare
	n_name		alias for $1;
begin
	insert into mi_manufacturer (name) values (n_name);
	return 1;
end;' language 'plpgsql';

create or replace function mi_importance__new (varchar, integer) returns integer as '
declare
	n_name		alias for $1;
	n_sort		alias for $2;
begin
	insert into mi_importance (name, sort_value) values (n_name, n_sort);
	return 1;
end;' language 'plpgsql';

create or replace function mi_eqmt_status__new (varchar) returns integer as '
declare
	n_name		alias for $1;
begin
	insert into mi_eqmt_status (name) values (n_name);
	return 1;
end;' language 'plpgsql';

create or replace function mi_operating_system__new (varchar) returns integer as '
declare
	n_name		alias for $1;
begin
	insert into mi_operating_system (name) values (n_name);
	return 1;
end;' language 'plpgsql';

