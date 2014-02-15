-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Oct-23 17:08 (EDT)
-- Function: 
--
-- $Id: forums-init.sql,v 1.5 2010/01/15 18:13:19 jaw Exp $

select mi_group__new( 'forumadmin', 'forums system admin' );

select mi_g_object_type__new( 'forums/group',
			   'forums/view-forum',
			   'mi_forum_group',
			   'group_id',
			   'mi_forum_name',
			   NULL,
			   NULL );

select mi_g_object_type__new( 'forums/q',
			   'forums/view-thread',
			   'mi_content',
			   'content_id',
			   NULL,
			   NULL,
			   mi_g_object_type('generic/content') );

select mi_g_object_type__new( 'forums/a',
			   'forums/view-thread',
			   'mi_content',
			   'content_id',
			   NULL,
			   'mi_forums_a_better',
			   mi_g_object_type('generic/content') );

