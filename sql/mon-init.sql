-- Copyright (c) 2004 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Created: 2004-Jan-08 16:55 (EST)
-- Function: 
--
-- $Id: mon-init.sql,v 1.1 2006/07/15 22:02:45 jaw Exp $

select g_object_type__new( 'mon/user',		-- type name
			   'mon/view-user',	-- view url
			   'mon_user',		-- table
			   'user_id',		-- primary key
			   'mon_user_name',	-- name function
			   NULL,		-- better function
			   NULL );		-- supertype

select g_object_type__new( 'mon/monitor',
			   'mon/view-monitor',
			   'monitor',
			   'mon_id',
			   'monitor_name',
			   NULL,
			   NULL );

