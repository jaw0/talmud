-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Feb-05 11:43 (EST)
-- Function: eqmt tracking - what is where?
--
-- $Id: eqmt-dm.sql,v 1.10 2010/01/16 05:35:15 jaw Exp $

-- we want to know where all of our eqmt is,
-- and all eqmt in any of our facilities


create table mi_fac_type (
       name			varchar(32)	primary key
);

-- where are our facilities?
create table mi_facility (
       fac_id			isa_object,
       -- descriptive friendly name: "Harrisburg POP", "Main Office"
       name			varchar(128)	not null unique,
       -- based on CLLI code country/state/city/co/arbitrary-alpha
       -- eg: uspaphlafglta
       code			varchar(16)	not null unique,
       npa			char(3),
       nxx			char(3),
       postal			text,

       fac_type			varchar(32)	not null references mi_fac_type on update cascade
);

-- what type of hardware
create table mi_hw_type (
       hw_type_id		varchar(6)	primary key,
       name			varchar(32)	not null unique
);

create table mi_manufacturer (
       name			varchar(32)	primary key
);

-- how important is a piece of eqmt?
create table mi_importance (
       name			varchar(32)	primary key,
       sort_value		integer		not null
);

create table mi_eqmt_status (
       name			varchar(32)	primary key
);

create table mi_operating_system (
       name		        varchar(32)	primary key
);

-- an actual piece of eqmt
create table mi_eqmt (
       eqmt_id			isa_object,
       fqdn			varchar(64)	not null,
       owner			ref_object	on delete set null,

       height			integer,	-- in U

       hw_type_id		varchar		not null references mi_hw_type,
       manuf			varchar(32)	not null references mi_manufacturer on update cascade,
       hw_model			varchar(32),
       hw_specs			varchar(200),
       -- RSN - mobo, cpu, ram, disk, cards

       serialno			varchar(32),

       os_name			varchar(32)	references mi_operating_system on delete cascade on update cascade,
       os_ver			varchar(32),
       os_patchlevel		varchar(32),	-- QQQ

       function			varchar(200),

       -- the accting people probably want to know various things
       asset_tag		varchar(32),
       purchased		timestamp(2),
       -- warranty info?

       -- where-o-where is this equipment
       fac_id			refs(mi_facility)	not null,
       rack_no			integer,	-- what rack
       rack_pos			integer,	-- where in rack
       location_more		varchar(100),	-- other details on its location

       -- how is it hooked up
       console_dev		refs(mi_eqmt)	on delete set null,
       console_port		varchar(32),
       power_dev		refs(mi_eqmt)	on delete set null,
       power_port		varchar(32),

       import_id		varchar(32)	not null references mi_importance on update cascade,
       status_id		varchar(32)	not null references mi_eqmt_status on update cascade,

       installed		timestamptz	default now()
);
create index mi_eqmt_owner_idx on mi_eqmt(owner);
create index mi_eqmt_fac_idx   on mi_eqmt(fac_id);
create index mi_eqmt_fqdn_idx  on mi_eqmt(fqdn);
create index mi_eqmt_cons_idx  on mi_eqmt(console_dev);
create index mi_eqmt_pwer_idx  on mi_eqmt(power_dev);

create table mi_interface (
       iface_id			isa_object,
       eqmt_id			refs(mi_eqmt)	on delete cascade,
       iface_name		varchar(64),
       ipaddr			inet,
       mac			macaddr,
       switch_id		refs(mi_eqmt)	on delete set null,
       switch_port		varchar(32),
       vlan			varchar(32)
);


create index mi_iface_eqmt_idx   on mi_interface(eqmt_id);
create index mi_iface_switch_idx on mi_interface(switch_id);



