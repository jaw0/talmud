-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Oct-03 19:56 (EDT)
-- Function: 
--
-- $Id: search-init.sql,v 1.4 2010/01/15 18:13:22 jaw Exp $

-- we create one object to hold search indexer timestamps

select mi_g_object_type__new( 'search/object',
			   NULL,
			   NULL,
			   NULL, 
			   NULL,
			   NULL,
			   NULL );

select mi_g_object__new_type ('search/object');

