-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-May-03 15:07 (EDT)
-- Function: ticket system functions
--
-- $Id: tkt-fnc.sql,v 1.11 2010/08/21 23:11:48 jaw Exp $



create or replace function mi_tkt_section__new (varchar, varchar, varchar) returns integer as '
declare
	n_name		alias for $1;
	n_tag		alias for $2;
	n_email		alias for $3;

	v_sid		t_object;
begin

	select into v_sid mi_g_object__new_type( ''tkt/section'' );

	insert into mi_tkt_section (section_id, name, tag, mail_from)
	  values( v_sid, n_name, n_tag, n_email);

	return 1;
end;' language 'plpgsql';

-- name
create or replace function mi_ticket_name (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;
	v_name		varchar;
begin
	v_name := ''#'' || tkt_number from mi_ticket where tkt_id = v_oid;

	if v_ext then
	   return ''tkt: '' || v_name;
	else
	  return v_name;
	end if;
end;' language 'plpgsql';

create or replace function mi_tkt_section_name (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;	-- not used
	v_name		varchar;
begin
	v_name := name from mi_tkt_section where section_id = v_oid;
	if v_ext then
	   return ''sect: '' || v_name;
	else
	  return v_name;
	end if;

end;' language 'plpgsql';


create or replace function mi_tkt_event_name (t_object, bool) returns varchar as '
declare
	v_oid		alias for $1;
	v_ext		alias for $2;

        new_oid	        t_object;
begin
	new_oid := tkt_id from mi_tkt_event where event_id = v_oid;
	if v_ext then
	    return ''tktev: '' || mi_ticket_name( new_oid, false );
	else
	    return mi_ticket_name( new_oid, false );
	end if;
end;' language 'plpgsql';

create or replace function mi_tkt_event_better (t_object) returns t_object as '
declare
	v_oid		alias for $1;
begin
	return tkt_id from mi_tkt_event where event_id = v_oid;
end;' language 'plpgsql';

create or replace function mi_tkt_content_better (t_object) returns t_object as '
declare
	v_oid		alias for $1;
begin

        return tkt_id from mi_tkt_event inner join mi_g_object on (refers_to = event_id)
               where g_obj_id = v_oid;

end;' language 'plpgsql';

----------------------------------------------------------------
-- trigger on tkt_event insert
-- update ticket.updated on any insert into tkt_event
-- update closed if event closes ticket

-- if the event is on a tkt which was merged into another
-- move the event onto the new ticket, fill in tkt_orig,
-- fill in updated, closed on both

create or replace function mi_update_ticket_on_event ()
returns opaque as '
declare
	v_ticket_id	t_object;
	v_ticket_mi	t_object;
	v_status	varchar;
begin
	v_ticket_id := NEW.tkt_id;

	select merged_into
	    into v_ticket_mi
	    from mi_ticket
	    where tkt_id = v_ticket_id;

	select name
	    into v_status
	    from mi_tkt_status INNER JOIN mi_ticket USING (status_id)
	    where tkt_id = v_ticket_id;

	-- update ticket.updated
	update mi_ticket set updated = now()
	    where tkt_id = v_ticket_id;

        -- update ticket.closed
	if v_status = ''closed'' then
	     update mi_ticket set closed = now()
	         where tkt_id = v_ticket_id;
	end if;

	-- was this merged somewhere else
	if v_ticket_mi IS NOT NULL then
	     NEW.tkt_id      := v_ticket_mi;
	     NEW.tkt_id_orig := v_ticket_id;

	     -- update timestamps on new ticket
	     update mi_ticket set updated = now()
		 where tkt_id = v_ticket_mi;

	     if v_status = ''closed'' then
	         update mi_ticket set closed = now()
		     where tkt_id = v_ticket_mi;
	     end if;

	end if;

	return NEW;
end;' language 'plpgsql';

create trigger mi_update_ticket_on_event_tr before insert on mi_tkt_event
for each row execute procedure mi_update_ticket_on_event();

----------------------------------------------------------------
-- trigger to maintain task priority, active_p
----------------------------------------------------------------
create or replace function mi_update_task_from_tkt () returns opaque as '
begin
    -- set priority => sortkey
    if NEW.priority_id is not null then
        update mi_task set sortkey = (select sort_value from mi_tkt_priority where priority_id = NEW.priority_id)
	       where task_id = NEW.tkt_id;
    end if;

    -- set active_p
    if NEW.status_id is not null then
       update mi_task set active_p = (select active_p from mi_tkt_status where status_id = NEW.status_id)
	       where task_id = NEW.tkt_id;
    end if;

    return NEW;
end;' language 'plpgsql';

create trigger mi_update_task_from_tkt_tr before insert or update on mi_ticket
for each row execute procedure mi_update_task_from_tkt();
