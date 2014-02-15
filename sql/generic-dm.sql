-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Sep-25 23:12 (EDT)
-- Function: supplemental generic stuff
--
-- $Id: generic-dm.sql,v 1.7 2010/01/15 18:13:20 jaw Exp $

create table mi_charset (
       -- "US-ASCII", "iso-8859-15"
       charset			varchar(16)	primary key
);
create table mi_language_code (
       -- can be either "en" or "en_us"
       lang			varchar(5)	primary key
);

-- comments, articles, news, ...
create table mi_content (
       content_id		isa_object,
       -- active, deleted, maybe: pending, expired, 
       status			varchar(16)	not null check(status in ('active', 'deleted'))
							 default 'active',

       -- most content will have object type = generic/content
       -- type further defines the type of content
       content_type		varchar(128),	-- news, etp, tkt, comment, ...
       sortkey			varchar(128),
       searchable_p		bool		default true,

       charset			varchar(16)	references mi_charset default 'US-ASCII',
       lang			varchar(5)	references mi_language_code default 'en_us',
       mime_type		varchar(128)	not null
);

create table mi_content_version (
       version_id		isa_object,
       content_id		refs(mi_content)	on delete cascade not null,
       current_version_p	bool			default true,
       -- one line summary or title
       summary			varchar(128),
       -- the actual content       
       content			bytea		not null
);
create index mi_content_vers_cont_idx on mi_content_version(content_id);

