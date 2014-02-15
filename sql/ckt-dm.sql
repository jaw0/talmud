-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Oct-10 17:22 (EDT)
-- Function: circuits
--
-- $Id: ckt-dm.sql,v 1.8 2010/01/15 18:13:18 jaw Exp $

create table mi_ckt_phys (
       name			varchar(32)	primary key,
       sort_value		integer
);

create table mi_ckt_srvc (
       name			varchar(32)	primary key,
       sort_value		integer
);

create table mi_ckt_end (
       ckt_end_id		isa_object,
       location			text,
       dlci			varchar(32),
       spid			varchar(32),
       e164			varchar(32),
       pvc			varchar(32),
       channels			varchar(32),
       vlan			varchar(32),
       router			ref_object	on delete set null,
       interface		varchar(32),
       jack			varchar(32)

       -- ...

);
create index mi_ckt_end_router_idx on mi_ckt_end(router);


create table mi_circuit (
       circuit_id		isa_object,

       telco			varchar(64),
       status			varchar(16)	not null default 'active'
						check (status in ('active', 'pending', 'terminated')),
       phys_type		varchar(32)	references mi_ckt_phys,
       srvc_type		varchar(32)	references mi_ckt_srvc,
       encap			varchar(32),
       installed		timestamp(2)	default now(),
       dlr_on_file		bool		default false,
       order_no			varchar(64),
       
       a_end			refs(mi_ckt_end)	on delete cascade,
       z_end			refs(mi_ckt_end)	on delete cascade

);
create index mi_ckt_a_idx on mi_circuit(a_end);
create index mi_ckt_z_idx on mi_circuit(z_end);

create table mi_ckt_wire (
       wire_id			isa_object,
       circuit_id		refs(mi_circuit)	on delete cascade not null,
       -- QQQ should telco be a ref to either a telco table or contact?
       telco			varchar(64),
       id			varchar(64)
);

create index mi_ckt_wire_ckt_idx on mi_ckt_wire(circuit_id);
