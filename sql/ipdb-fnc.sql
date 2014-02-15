-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Oct-29 17:12 (EST)
-- Function: 
--
-- $Id: ipdb-fnc.sql,v 1.4 2010/01/15 18:13:21 jaw Exp $

create or replace function mi_ipdb_registry_name (bigint, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;
begin
	return name from mi_ipdb_registry where registry_id = v_oid;
end;' language 'plpgsql';

create or replace function mi_ipdb_meta_name (bigint, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;
begin
	return netname from mi_ipdb_meta where meta_id = v_oid;
end;' language 'plpgsql';

create or replace function mi_ipdb_block_name (bigint, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;
begin
	return netblock || ''/'' || size from mi_ipdb_block where block_id = v_oid;
end;' language 'plpgsql';

