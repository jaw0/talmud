-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Oct-15 15:08 (EDT)
-- Function: ip address block allocation tracking
--
-- $Id: ipdb-dm.sql,v 1.8 2010/01/16 05:35:16 jaw Exp $


create table mi_ipdb_config (
       param			varchar(32)	primary key,
       descr			varchar(128),
       value			varchar(1024)
);

create table mi_ipdb_swip (
       swip_id			varchar		primary key,
       label			varchar(32),
       index			integer,

       unique(label, index)
);

create table mi_ipdb_pool (
       name			varchar(32)	primary key
);

create table mi_ipdb_registry (
       registry_id		isa_object,
       name			varchar(32)	unique,
       email			varchar(32),	-- email addr for swip requests
       handle			varchar(32),	-- handle to use on swip requests
       maintainer		varchar(32)	-- maintainer to use on sqip requests
);

-- blocks allocated to us
create table mi_ipdb_meta (
       meta_id			isa_object,
       netblock			varchar(64)	not null,
       size			integer		not null,
       netname			varchar(32)	not null unique,
       registry_id		refs(mi_ipdb_registry)	 on delete set null,
       swipprefix		varchar(8),

       unique( netblock, size )

);
create index mi_ipdb_meta_block_idx on mi_ipdb_meta(netblock);
create index mi_ipdb_meta_name_idx  on mi_ipdb_meta(netname);
create index mi_ipdb_meta_regy_idx  on mi_ipdb_meta(registry_id);

create table mi_ipdb_block (
       block_id			isa_object,
       meta_id			refs(mi_ipdb_meta)	on delete cascade,

       netblock			varchar(64)	not null,
       size			integer		not null,

       sort_low			numeric,
       sort_high		numeric,

       status			varchar(16)	not null
				check (status in ('available', 'allocated', 'reserved')),

       usage			varchar(16)
				check (usage in ('internal', 'customer', 'employee')),

       descr			varchar(200),
       pool			varchar(32)	references mi_ipdb_pool on delete set null on update cascade,

       swip_id			varchar(64)	unique,
       justified_p		bool		not null default false,

       -- cust_id			bigint		references g_object on delete set null on update cascade,
       -- cust data...
       
       unique( netblock, size )

);

create index mi_ipdb_block_sortlow_idx on mi_ipdb_block(sort_low);
create index mi_ipdb_block_meta_idx    on mi_ipdb_block(meta_id);

