-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Feb-05 11:43 (EST)
-- Function: ticket system datamodel
--
-- $Id: tkt-dm.sql,v 1.9 2010/01/16 05:35:17 jaw Exp $


-- the 4 tables (section, status, priority, severity) will be "static"
-- as a convience, id=0 should be the prefered default for new tickets

-- we'll want to divide tickets into sections/groups/departments/...
-- such NOC, provisioning, texupport, accting, etc.
create table mi_tkt_section (
       section_id		isa_object,
       name			varchar(32)	not null unique,
       -- tag = short name, used in Subject: [FOO #345]
       tag			varchar(8)	not null unique,
       mail_from		varchar(200)	
);

-- priority indicates "when does this need to be done"
-- numerically higher priority => "do it now!"
-- numerically lower priority  => "do it later"
--           I'm imagining this being set by a manager (or other responsible party)
--           to indicate to staff the order work should be done
--           ie. this number represents "policy"
create table mi_tkt_priority  (
       priority_id		integer		primary key,
       sort_value		integer		not null,
       color			varchar(6)	not null,	-- for web page
       name			varchar(32)	not null unique
);


-- severity idicates "how much damage"
-- numerically higher severity => "big damage", "lots of customers", etc.
-- numerically lower severity  => "little damage", "one customer", etc.
--           I'm imagining this set at ticket creation (or shortly therafter)
--           I see this as a quantitative "technical" parameter
create table mi_tkt_severity (
       severity_id		integer		primary key,
       sort_value		integer		not null,
       -- I'm afraid to color both columns as the resulting
       -- web page will be a fruit salad disaster
       name			varchar(32)	not null unique
);

create table mi_tkt_status (
       status_id		integer		primary key,
       -- normally we will display only "active" tickets
       -- some states will be active, and others not...
       active_p			bool		not null,
       name			varchar(32)	not null unique
);


create sequence tkt_number_seq start 1001;
create table mi_ticket (
       tkt_id			subclass(mi_task),
       tkt_number		integer		unique,
       merged_into		refs(mi_ticket)	on delete cascade,

       -- any time these are modified, there will be a tkt_event
       status_id		integer		not null references mi_tkt_status   default 0,
       priority_id		integer		not null references mi_tkt_priority default 0,
       severity_id		integer		not null references mi_tkt_severity default 0,
       -- these could be user_acct, contact, or tkt_user
       creator			ref_object	on delete set null,

       -- update via trigger on tkt_event
       updated			timestamptz	not null default now(),
       -- update via trigger on tkt_event
       closed			timestamptz

       -- NB: summary in task, section in object.refers_to

);
create index mi_tkt_merged_idx  on mi_ticket(merged_into);
create index mi_tkt_creator_idx on mi_ticket(creator);


-- events are: updates, changes, etc to tickets
create table mi_tkt_event (
       event_id			isa_object,
       tkt_id			refs(mi_ticket)	on delete cascade not null,
       -- if ticket was merged, this is the original ticket
       tkt_id_orig		refs(mi_ticket)	on delete set null,
       -- QQQ - isn't this the same as g_object.created_date ???
       event_when		timestamptz	not null default now(),
       -- this could be user_acct, contact, or tkt_user
       event_who		ref_object      on delete set null,

       -- keep track of staff time spent on this
       labor			integer,
       -- should the customer be billed?
       billable_p		bool		default FALSE,

       -- should action ref an action table?
       -- modify = change prio/seve/section/...; update = add content
       action			varchar(16)	not null check (action in
						('create', 'update', 'attach', 'merge',
						    'modify' )),
       details			varchar(200),	-- addtnl details on the action

       -- current values of ticket params
       owner			ref_object	on delete set null,
       status_id		integer		references mi_tkt_status

);
create index mi_tkt_event_tkt_idx   on mi_tkt_event(tkt_id);
create index mi_tkt_event_orig_idx  on mi_tkt_event(tkt_id_orig);
create index mi_tkt_event_who_idx   on mi_tkt_event(event_who);
create index mi_tkt_event_owner_idx on mi_tkt_event(owner);

