-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Sep-26 11:53 (EDT)
-- Function: user data model
--
-- $Id: users-dm.sql,v 1.7 2010/08/21 16:17:11 jaw Exp $


create table mi_person_category (
       category			varchar(32)	primary key
);

create table mi_party (
       party_id			isa_object,
       email			varchar(128)	unique
);

create table mi_person (
       person_id		subclass(mi_party),
       realname			varchar(128)	not null,
       category			varchar(32)	references mi_person_category on delete set null on update cascade,
       public_p			bool		default true
);

create table mi_user (
       user_id	  		subclass(mi_person),
       passwd			varchar(128)	not null,
       status			varchar(16)	not null default 'active'
				check( status in('active', 'locked') ),

       -- user will be able to log in with either nickname or email
       nickname			varchar(32)	not null unique,

       url			varchar(128),
       photo_url		varchar(128),
       biography		text,

       -- various preferences
       -- default ticket section
       section_id		ref_object	on delete set null,
       notifyme_p		boolean		default true,
       -- css file
       theme			varchar(64)
);
create index mi_user_section_idx on mi_user(section_id);

create view mi_site_user as select *
       from mi_user, mi_person, mi_party
       where user_id = person_id and user_id = party_id and party_id = person_id;


create table mi_group (
       group_id			subclass(mi_party),
       groupname		varchar(32)	not null unique,
       descr			varchar(128)
);

create table mi_party_group (
       party_id			ref_object	on delete cascade,
       group_id			ref_object	on delete cascade,

       unique( party_id, group_id )
);

create index mi_party_group_user_idx  on mi_party_group(party_id);
create index mi_party_group_group_idx on mi_party_group(group_id);

-- future plans: this will be a table of party_group collapsed down
create view mi_user_group as select *, party_id as user_id from mi_party_group;

create table mi_contact_data (
       data_id			varchar		primary key,
       contact_id		ref_object	on delete cascade,
       availability		varchar(32),
       field			varchar(32)	not null,
       value			text
);
create index mi_contact_data_idx  on mi_contact_data(contact_id);
create index mi_contact_field_idx on mi_contact_data(field);

