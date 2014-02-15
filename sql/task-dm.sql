-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Created: 2003-Nov-10 12:58 (EST)
-- Function: generic tasks - things to do
--
-- $Id: task-dm.sql,v 1.3 2010/01/15 18:13:22 jaw Exp $

create table mi_task (
       task_id			isa_object,
       owner			ref_object	on delete set null,
       active_p			bool		not null default true,
       public_p			bool		not null default true,
       deadline			timestamp,
       sortkey			varchar(128),
       summary			varchar(200)	not null
);

create index mi_task_owner_idx  on mi_task(owner);

