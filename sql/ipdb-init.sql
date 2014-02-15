-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Oct-29 17:12 (EST)
-- Function: 
--
-- $Id: ipdb-init.sql,v 1.4 2010/01/15 18:13:21 jaw Exp $

select mi_g_object_type__new( 'ipdb/registry',
			   'ipdb/view-registry',
			   'mi_ipdb_registry',
			   'registry_id',
			   'mi_ipdb_registry_name',
			   NULL,
			   NULL );

select mi_g_object_type__new( 'ipdb/meta',
			   'ipdb/view-meta',
			   'mi_ipdb_meta',
			   'meta_id',
			   'mi_ipdb_meta_name',
			   NULL,
			   NULL );

select mi_g_object_type__new( 'ipdb/block',
			   'ipdb/view-block',
			   'mi_ipdb_block',
			   'block_id',
			   'mi_ipdb_block_name',
			   NULL,
			   NULL );

select mi_g_rel_type__new( 'ipdb/block/cust', 'ipdb/block', NULL );

select mi_group__new( 'ipdbadmin', 'IPDB admin' );

insert into mi_ipdb_config (param, descr) values ('swip_from_addr', 'From Email Address for SWIPs');
insert into mi_ipdb_config (param, descr) values ('swip_cc_addr',   'Email Addr to CC SWIPs to');

