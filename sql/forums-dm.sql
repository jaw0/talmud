-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Oct-08 21:02 (EDT)
-- Function: 
--
-- $Id: forums-dm.sql,v 1.6 2010/01/15 18:13:19 jaw Exp $

create table mi_forum_group (
       group_id			isa_object,
       name			varchar(64)	not null unique,
       descr			varchar(128),
       active_p			bool		not null default true

);

-- non-normal data for simpler access
-- maintained by trigger on content
create table mi_forum_post_info (
       post_id			subclass(mi_content),
       last_reply		timestamp	default now(),
       n_replies		integer		default 0
);

