-- Copyright (c) 2010 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Created: 2010-Aug-20 18:52 (EDT)
-- Function: 
--
-- $Id: bkmk-init.sql,v 1.1 2010/08/21 16:06:54 jaw Exp $

select mi_g_rel_type__new( 'bkmk/attach', 'users/user', NULL );	-- user => any

