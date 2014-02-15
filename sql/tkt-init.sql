-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-May-03 11:10 (EDT)
-- Function: init data for tkt
--
-- $Id: tkt-init.sql,v 1.9 2010/08/21 23:11:48 jaw Exp $

select mi_group__new( 'tktadmin', 'ticket system admin' );
insert into mi_person_category values ('tktemail');

select mi_g_object_type__new( 'tkt/content',
			   -- QQQ - or special url that redirects to ticket
			   'generic/view-content',
			   'mi_content',
			   'content_id',
			   NULL,
			   'mi_tkt_content_better',
			   mi_g_object_type('generic/content') );

select mi_g_object_type__new( 'tkt/ticket',
			   'tkt/view-tkt',
			   'mi_ticket',
			   'tkt_id',
			   'mi_ticket_name',
			   NULL,
			   mi_g_object_type('generic/task') );

select mi_g_object_type__new( 'tkt/section',
			   'tkt/view-section',
			   'mi_tkt_section',
			   'section_id',
			   'mi_tkt_section_name',
			   NULL,
			   NULL );

select mi_g_object_type__new( 'tkt/event',
			   NULL,
			   'mi_tkt_event',
			   'event_id',
			   'mi_tkt_event_name',
			   'mi_tkt_event_better',
			   NULL );

select mi_g_rel_type__new( 'tkt/attach', 'tkt/event', NULL );	-- tkt/event => any

-- create initial sections
select mi_tkt_section__new  ( 'un-classified', 'UNK', NULL );


insert into mi_tkt_priority (priority_id, sort_value, color, name) values
(1,	10,	'DDDDDD', 	'never'),
(2,	20,	'DDDDDD', 	'low'),
(0,	50,	'FFFF00', 	'medium'),
(3,	60,	'FF0000', 	'high'),
(4,	90,	'FF0000', 	'critical');


-- the code makes certain workflow assumptions based
-- on the status name, modify with care
insert into mi_tkt_status (status_id, active_p, name) values
(0,	true,	'new'),
(1,	true,	'active'),
(2,	false,	'closed'),
(3,	false,	'dead'),
(4,	true,	'stalled'),
(5,	true,	'on hold');


insert into mi_tkt_severity (severity_id, sort_value, name) values
(1,	  0,	'un-important'),
(2,	 10,	'warning'),
(0,	 50,	'minor'),
(3,	 90,	'major'),
(4,	100,	'critical');

