-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Created: 2003-Nov-10 13:01 (EST)
-- Function: 
--
-- $Id: task-init.sql,v 1.2 2010/01/15 18:13:23 jaw Exp $

select mi_g_object_type__new( 'generic/task',
			   'generic/view-task',
			   'mi_task',
			   'task_id',
			   'mi_task_name',
			   NULL,
			   NULL );
