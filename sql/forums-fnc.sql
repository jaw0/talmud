-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Oct-23 17:08 (EDT)
-- Function: 
--
-- $Id: forums-fnc.sql,v 1.9 2010/01/16 05:35:16 jaw Exp $

create or replace function mi_forum_name (t_object, bool) returns varchar as '
declare
        v_oid           alias for $1;
        v_ext           alias for $2;
        v_name          varchar;
begin
        v_name := name from mi_forum_group where group_id = v_oid;

        if v_ext then
           return ''forum: '' || v_name;
        else
          return v_name;
        end if;
end;' language 'plpgsql';

create or replace function mi_forums_a_better (t_object) returns t_object as '
declare
        v_oid           alias for $1;
begin
        return refers_to from mi_g_object where g_obj_id = v_oid;
end;' language 'plpgsql';


-- ################################################################
-- trigger on content to maintain last_reply timestamp
-- ################################################################

create or replace function mi_forum_reply_settime () returns opaque as '
declare
        v_oid           t_object;
        v_type          t_type;
begin

-- forum/q => insert new row into forum_post_reply
-- forum/a => update row in forum_post_reply

        v_oid  := NEW.content_id;
        v_type := g_obj_type from mi_g_object where g_obj_id = v_oid;

        if v_type = mi_g_object_type(''forums/a'') then
            update mi_forum_post_info set last_reply = now(), n_replies = (n_replies + 1)
                where post_id = (select refers_to from mi_g_object where g_obj_id = v_oid);
	else
	    if v_type = mi_g_object_type(''forums/q'') then
		insert into mi_forum_post_info (post_id) values (v_oid);
	    end if;
	end if;

	return NEW;
end;' language 'plpgsql';

create trigger mi_forum_reply_settime_tr after insert on mi_content for each row
execute procedure mi_forum_reply_settime ();

