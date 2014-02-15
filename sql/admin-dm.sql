-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Sep-26 09:25 (EDT)
-- Function: administrative tables
--
-- $Id: admin-dm.sql,v 1.6 2010/01/15 18:13:17 jaw Exp $

-- put web auth cookies in db
create table mi_web_cookie (
        cookie_id               char(64)        primary key,
        user_id			refs(mi_user)	on delete cascade,
        issued                  timestamptz     not null  default now(),
        expires                 timestamptz     not null  default now() + CAST('1 month' AS interval),
        server                  varchar(64)     not null,
        userip                  inet            not null

);
create index mi_cookie_user_idx on mi_web_cookie(user_id);

create table mi_login_acct (
       user_id			refs(mi_user)	on delete set null,
       cookie_id		char(64)	references mi_web_cookie on delete set null,
       username			varchar(64),
       acct_time		timestamptz	default now(),
       success_p		bool,		-- did user successfully log in
       fromip			inet

);
create index mi_login_acct_uid_idx on mi_login_acct(user_id);
create index mi_login_cookie_idx   on mi_login_acct(cookie_id);
create index mi_login_acct_ip_idx  on mi_login_acct(fromip);


create table mi_sys_config (
       param			varchar(32)	primary key,
       descr			varchar(128),
       type			varchar(16)	not null,
       value			varchar(1024)
);

