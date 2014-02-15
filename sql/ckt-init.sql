-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Oct-13 21:16 (EDT)
-- Function: 
--
-- $Id: ckt-init.sql,v 1.9 2010/08/21 23:11:48 jaw Exp $

select mi_g_object_type__new( 'ckt/circuit',
			   'ckt/view-ckt',
			   'mi_circuit',
			   'circuit_id',
			   'mi_ckt_name',
			   NULL,
			   NULL );

select mi_g_object_type__new( 'ckt/end',
			   NULL,
			   'mi_ckt_end',
			   'ckt_end_id',
			   'mi_ckt_end_name',
			   'mi_ckt_end_better',
			   NULL );

select mi_g_object_type__new( 'ckt/wire',
			   NULL,
			   'mi_ckt_wire',
			   'wire_id',
			   'mi_ckt_wire_name',
			   'mi_ckt_wire_better',
			   NULL );

select mi_g_rel_type__new( 'ckt/ckt/attach',  'ckt/circuit', NULL );
select mi_g_rel_type__new( 'ckt/end/attach',  'ckt/end',     NULL );
select mi_g_rel_type__new( 'ckt/wire/attach', 'ckt/wire',    NULL );

insert into mi_ckt_phys (name, sort_value) values
('DDS',			10),
('T1',			20),
('T3',			30),
('OC3',			40),
('OC12',		50),
('ethernet',		100),
('fast ethernet',	110),
('gig-ethernet',	120);


insert into mi_ckt_srvc (name, sort_value) values
('fractional',	10),
('channelized',	20),
('straight',	30),
('frame relay',	40),
('smds',	50),
('atm',		60),
('frame hub',	100),
('smds hub',	110),
('atm hub',	120),
('channel hub',	130),
('voice',	140),
('internet',	200);



