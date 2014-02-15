-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-May-03 10:38 (EDT)
-- Function: misc sql funcs
--
-- $Id: obj-fnc.sql,v 1.10 2010/08/21 16:06:54 jaw Exp $

create or replace function mi_g_obj_next_id() returns t_object as '
declare
	v_nid			t_object;
begin
	-- fwAAAQ = base64(127.0.0.1)
	select into v_nid ''fwAAAQ_'' || lpad(nextval( ''mi_g_object_seq'' )::varchar, 9, ''0'');
	return v_nid;
end;' language 'plpgsql';

-- create a new object type
create or replace function mi_g_object_type__new (varchar, varchar, varchar, varchar, varchar, varchar, t_type) returns t_type as '
declare
	new_tname		alias for $1;	-- name of type
	new_url			alias for $2;	-- view url
	new_tbl			alias for $3;	-- table name
	new_pk			alias for $4;	-- primary key column
	new_nf			alias for $5;	-- name function
	new_bf			alias for $6;	-- better function
	new_st			alias for $7;	-- supertype

	v_type			t_type;
begin
	select into v_type nextval( ''mi_g_object_type_seq'' );
	-- select into v_type mi_g_obj_next_id();

	insert into mi_g_object_type (g_obj_type, g_obj_type_name, g_obj_url,
	       g_obj_table_name, g_obj_pk_name, g_obj_supertype, g_obj_name_fnc, g_obj_better_fnc)
	       values (v_type, new_tname, new_url, new_tbl, new_pk, new_st, new_nf, new_bf);

	return v_type;
end;' language 'plpgsql';

-- create a new relation type
create or replace function mi_g_rel_type__new (varchar, varchar, varchar) returns t_type as '
declare
	new_name		alias for $1;
	new_ta			alias for $2;
	new_tb			alias for $3;
	v_type			t_type;
begin
	v_type := mi_g_object_type__new( new_name, NULL, NULL, NULL, NULL, NULL, mi_g_object_type(''obj/rel'') );
	insert into mi_g_rel_type (g_rel_type_id, type_a, type_b) values
	       (v_type, mi_g_object_type(new_ta), mi_g_object_type(new_tb) );
	return v_type;
end;' language 'plpgsql';

-- find the object type given the name
create or replace function mi_g_object_type(varchar)
returns t_type as '
declare
	with_tname		alias for $1;
begin
	return g_obj_type from mi_g_object_type where g_obj_type_name = with_tname;
end;' language 'plpgsql' with (iscachable);

-- create a new object
create or replace function mi_g_object__new (t_object,t_type,t_object,varchar,t_object)
returns t_object as '
declare
  new__object_id              alias for $1;  -- default null
  new__object_type            alias for $2;
  new__creation_user          alias for $3;  -- default null
  new__acl		      alias for $4;  -- default null
  new__refers		      alias for $5;  -- default null

  v_object_id                 t_object;
begin
  if new__object_id is null then
    v_object_id := mi_g_obj_next_id();
  else
    v_object_id := new__object_id;
  end if;

  insert into mi_g_object
   (g_obj_id, g_obj_type,
    created_user, acl, refers_to)
  values
   (v_object_id, new__object_type, 
    new__creation_user, new__acl, new__refers);

  return v_object_id;
  
end;' language 'plpgsql';

-- quick object create shortcut
create or replace function mi_g_object__new_type (varchar)
returns t_object as '
declare
	with_tname		alias for $1;

	v_type			t_type;
	v_id			t_object;
begin
	select into v_type mi_g_object_type(with_tname);
	select into v_id mi_g_object__new( NULL, v_type, NULL, NULL, NULL );

	return v_id;
end;' language 'plpgsql';

-- create a new relation
create or replace function mi_g_obj_rel__new (t_object,t_object,varchar, varchar,t_object,t_object)
returns t_object as '
declare
  new_object_id               alias for $1;  -- default null
  new_creation_user           alias for $2;  -- default null
  new_acl		      alias for $3;  -- default null
  new_rel_type		      alias for $4;
  new_obj_a		      alias for $5;
  new_obj_b		      alias for $6;
  v_object_id                 t_object;
begin

  v_object_id := mi_g_object__new( new_object_id,
				mi_g_object_type(new_rel_type),
				new_creation_user,
				new_acl,
				NULL );

  insert into mi_g_obj_rel (g_obj_rel_id, obj_a, obj_b) values
	 (v_object_id, new_obj_a, new_obj_b);

  return v_object_id;
  
end;' language 'plpgsql';


-- generic object name method
create or replace function mi_g_object_name_fnc (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;	-- not used
begin
	return ''obj:'' || v_oid;
end;' language 'plpgsql';

----------------------------------------------------------------
-- various virtual function dispatch functions
----------------------------------------------------------------

create or replace function mi_object_better (t_object) returns t_object as '
declare
	v_oid		alias for $1;
	v_type		t_type;
	v_fnc		varchar;
	v_exec		varchar;
	v_rec		record;
begin
	v_type := g_obj_type from mi_g_object where g_obj_id = v_oid;
	if v_type is null then
	   return NULL;
	end if;
	v_fnc := g_obj_better_fnc from mi_g_object_type where g_obj_type = v_type;
	if v_fnc is null then
	   return NULL;
	end if;

	v_exec := ''select '' || v_fnc || ''('' || quote_literal(v_oid) || '') as o'';
	for v_rec in execute v_exec loop
	    return v_rec.o;
	end loop;

	return NULL;

end;' language 'plpgsql';

create or replace function mi_object_best (t_object) returns t_object as '
declare
	v_oid		alias for $1;
begin
	return coalesce( mi_object_better(v_oid), v_oid );
end;' language 'plpgsql';


-- find best URL for an object
-- base url = '/foo'
-- full url = '/foo?oid=$oid'

create or replace function mi_object_baseurl (t_object) returns varchar as '
declare
	v_oid		alias for $1;
	v_type		t_type;
	v_rec		record;
	v_url		varchar;
	v_sup		t_type;
begin
	v_type := g_obj_type from mi_g_object where g_obj_id = v_oid;
	if v_type is null then
	   return NULL;
	end if;

	while 1 loop
	      select into v_rec * from mi_g_object_type where g_obj_type = v_type;
	      v_url := v_rec.g_obj_url;
	      v_sup := v_rec.g_obj_supertype;

	      if v_url is not null then
		 return v_url;
	      end if;

	      -- check parent type
	      if v_sup is not null then
		   v_type := v_sup;
	      else
		  -- no parent, no function
		  return NULL;
	      end if;
	end loop;

end;' language 'plpgsql';

create or replace function mi_object_fullurl (t_object) returns varchar as '
declare
	v_oid		alias for $1;
	v_url		varchar;
begin
	v_url := mi_object_baseurl( v_oid );
	if v_url is not null then
	   return v_url || ''?oid='' || v_oid;
	end if;
	return NULL;
end;' language 'plpgsql';

-- find best name for object
create or replace function mi_object_name (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;

	v_type		t_type;
	v_nf		varchar;
	v_sup		t_type;
	v_rec		record;
	v_exec		varchar;
	v_bool		varchar;
begin
	select into v_type g_obj_type from mi_g_object where g_obj_id = v_oid;
	if v_type is null then
	   return ''(unknown)'';
	end if;

	if v_ext then
	    v_bool := ''true'';
	else
	    v_bool := ''false'';
	end if;

	while 1 loop
	      select into v_rec * from mi_g_object_type where g_obj_type = v_type;
	      v_nf  := v_rec.g_obj_name_fnc;
	      v_sup := v_rec.g_obj_supertype;

	      if v_nf is not null then
		 -- found a function, get the name
		 v_exec := ''select '' || v_nf || ''('' || quote_literal(v_oid) || '', '' || v_bool || '') as n'';
		 -- raise notice ''executing: %'', v_exec;

		 for v_rec in execute v_exec loop
		     return v_rec.n;
		 end loop;
	      end if;

	      -- check parent type
	      if v_sup is not null then
		   v_type := v_sup;
	      else
		  -- no parent, no function
		  return mi_g_object_name_fnc( v_oid, v_ext );
	      end if;
	end loop;

end;' language 'plpgsql';

create or replace function mi_object_ahref (t_object) returns varchar as '
declare
    v_oid	    alias for $1;
    v_url	    varchar;
    v_name	    varchar;
begin
	v_name := mi_object_name(v_oid, false);
	if v_name is null then
	   return NULL;
	end if;

	v_url := mi_object_fullurl(v_oid);
	if v_url is null then
	   return NULL;
	end if;

	return ''<A HREF="/'' || v_url || ''">'' || v_name || ''</A>'';
end;' language 'plpgsql';

-- determine if an object is the specified type
create or replace function mi_object_isa (t_object, t_type) returns bool as '
declare
    v_oid	    alias for $1;
    v_isa	    alias for $2;
    v_type	    t_type;
begin

    v_type := g_obj_type from mi_g_object where g_obj_id = v_oid;

    loop
	if v_type = v_isa then
	   return true;
	end if;

	if v_type is null then
	   return false;
	end if;

	v_type := g_obj_supertype from mi_g_object_type where g_obj_type = v_type;
    end loop;

end;' language 'plpgsql';


----------------------------------------------------------------
-- update trigger to adjust modified_date
----------------------------------------------------------------
create or replace function mi_g_object__modify ()
returns opaque as '
begin
	NEW.modified_date := now();
	return NEW;
end;' language 'plpgsql';

create trigger mi_g_object__modify_tr before update on mi_g_object for each row 
  execute procedure mi_g_object__modify();

----------------------------------------------------------------
-- insert trigger to set default value of g_obj_rel.rel_type.name
----------------------------------------------------------------
create or replace function mi_g_obj_rel_set_name ()
returns opaque as '
declare
    v_name		varchar;
begin

    if NEW.rel_type_name is null then
        select into v_name g_obj_type_name from mi_g_object inner join mi_g_object_type
	       using (g_obj_type) where g_obj_id = NEW.g_obj_rel_id;

	NEW.rel_type_name := v_name;
    end if;

    return NEW;
end;' language 'plpgsql';

create trigger mi_g_obj_rel_set_name_tr before insert on mi_g_obj_rel for each row
  execute procedure mi_g_obj_rel_set_name();

