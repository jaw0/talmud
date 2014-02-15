-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Feb-05 11:43 (EST)
-- Function: generic objects datamodel
-- 
-- $Id: obj-dm.sql,v 1.8 2010/08/21 20:18:31 jaw Exp $


create sequence mi_g_object_type_seq start 1 cache 1;
create table mi_g_object_type (
       g_obj_type		t_type		primary key,
       -- what does that package use it for
       g_obj_type_name		varchar(128)	not null unique,

       -- we will generate redirects to /$url?oid=$obj
       g_obj_url		varchar(128),

       g_obj_supertype		t_type		references mi_g_object_type,
       g_obj_table_name		varchar(64),	-- name of table
       g_obj_pk_name		varchar(64),	-- name of primary key column
       g_obj_name_fnc		varchar(64),	-- function to return name
       g_obj_better_fnc		varchar(64)	-- function to return a better object

);

create sequence mi_g_object_seq start 100101 cache 4;
create table mi_g_object (
       g_obj_id			t_object	primary key,
       g_obj_type		t_type		not null references mi_g_object_type,

       g_obj_owner		ref_object	on delete set null,
       created_user		ref_object	on delete set null,
       created_date		timestamptz	not null default now(),
       modified_user		ref_object	on delete set null,
       modified_date		timestamptz,

       refers_to		ref_object	on delete cascade,
       acl			varchar(2000)
);

create index mi_g_object_owner_idxn  on mi_g_object(g_obj_owner);
create index mi_g_object_creator_idx on mi_g_object(created_user);
create index mi_g_object_moduser_idx on mi_g_object(modified_user);
create index mi_g_obj_type_idx       on mi_g_object(g_obj_type);
create index mi_g_obj_refer_idx	     on mi_g_object(refers_to);

-- extends g_object_type
create table mi_g_rel_type (
       g_rel_type_id		t_type		primary key references mi_g_object_type,
       type_a			t_type		references mi_g_object_type,
       type_b			t_type		references mi_g_object_type

       -- ...
);

create table mi_g_obj_rel (
       g_obj_rel_id		isa_object,
       rel_type_name		varchar(128)	not null,   -- default = g_object_type.name via trigger
       obj_a			ref_object	on delete cascade not null,
       obj_b			ref_object	on delete cascade not null,

       unique( rel_type_name, obj_a, obj_b )
);

create index mi_g_obj_rel_a_idx on mi_g_obj_rel(obj_a);
create index mi_g_obj_rel_b_idx on mi_g_obj_rel(obj_b);

