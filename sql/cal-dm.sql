-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Oct-08 16:12 (EDT)
-- Function: shared calendar system
--
-- $Id: cal-dm.sql,v 1.2 2003/10/23 03:36:42 jaw Exp $

-- QQQ - recurring events: one row, muliple rows?
-- in order to cancel one instance in a recurring event, need muliple rows

create table event (
       event_id			bigint		primary key references g_object on delete cascade,
       -- owner, group, activity, etc
       refers_to		bigint		references g_object on delete cascade,

       -- start and end of each occurrence
       start_time		time,
       end_time			time,

       -- start, end, and interval for recurring events
       start_date		date,
       end_date			date,
       recurrence		interval,

);

create table event_occurrence (

       event_id			bigint references event on delete cascade,
       start_time		timestamp,
       end_time			timestamp,

);

create user_event_map (

);

create table user_occurrence_map (

       user_id
       occur_id
       status		in ('pending', 'accepted', 'declined')

);
