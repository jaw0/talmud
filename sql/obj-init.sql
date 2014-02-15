-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-May-03 10:37 (EDT)
-- Function: insert initial data
--
-- $Id: obj-init.sql,v 1.4 2010/01/15 18:13:22 jaw Exp $

select mi_g_object_type__new( 'object', NULL, 'g_object', 'g_obj_id', 'g_object_name_fnc', NULL, NULL );

select mi_g_object_type__new( 'obj/rel', NULL, 'g_obj_rel', 'g_obj_rel_id', NULL, NULL, NULL );

