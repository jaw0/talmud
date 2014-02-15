-- Copyright (c) 2004 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Created: 2004-Jan-08 16:02 (EST)
-- Function: argus monitoring
--
-- $Id: mon-dm.sql,v 1.1 2006/07/15 22:02:45 jaw Exp $

create table mon_user (
       user_id	  		isa_object,

       email			varchar(128)	unique,
       realname			varchar(128)	not null,
       passwd			varchar(128)	not null,	-- encrypted

       status			varchar(16)	not null default 'active'
				check( status in('active', 'locked') ),

       notify			varchar(1000)	not null,
       escalate			varchar(1000),
       timezone			varchar(64),
       renotify			integer,
       -- RSN - various layout, style, etc controls?

       -- demographics, tracking, etc
       referer_url		varchar(1000),
       heard_from		varchar(1000),
       cust_type		varchar(32),

       -- to send literature, swag, ...
       postal			text

);

create table monitor (
       mon_id			isa_object,
       user_id			refs(mon_user)	on delete cascade not null,

       status			varchar(16)	not null default 'active'
				check( status in('trial', 'active', 'locked') ),

       hostname			varchar(64)	not null,
       service			varchar(64)	not null

);
create index mon_uid_idx    on monitor(user_id);

-- narrow table for any other parameters
create table mon_param (
       mon_id			refs(monitor)	on delete cascade not null,

       key			varchar(32)	not null,
       value			varchar(200)	not null,

       unique(mon_id, key)
);

