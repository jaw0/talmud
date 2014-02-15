-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Sep-26 09:27 (EDT)
-- Function: 
--
-- $Id: generic-init.sql,v 1.7 2010/01/15 18:13:20 jaw Exp $

-- create generic types
select mi_g_object_type__new( 'generic/content',
			   'generic/view-content',
			   'mi_content',
			   'content_id',
			   'mi_content_name',
			   NULL,
			   NULL );

select mi_g_object_type__new( 'generic/version',
			   NULL,	-- 'generic/view-content-version',
			   'mi_content_version',
			   'version_id',
			   'mi_content_version_name',
			   'mi_content_version_better',
			   NULL );

-- this lets us better display these content variants
select mi_g_object_type__new( 'etp/content',
			   'doc/view',
			   'mi_content',
			   'content_id',
			   NULL,
			   NULL,
			   mi_g_object_type('generic/content' ) );

select mi_g_object_type__new( 'news/content',
			   'generic/view-content',
			   'mi_content',
			   'content_id',
			   NULL,
			   NULL,
			   mi_g_object_type('generic/content') );

insert into mi_language_code (lang) values ('en_us');
insert into mi_charset (charset) values ('US-ASCII');
insert into mi_charset (charset) values ('ISO-8859-1');
insert into mi_charset (charset) values ('ISO-8859-2');
insert into mi_charset (charset) values ('ISO-8859-3');
insert into mi_charset (charset) values ('ISO-8859-4');
insert into mi_charset (charset) values ('ISO-8859-5');
insert into mi_charset (charset) values ('ISO-8859-6');
insert into mi_charset (charset) values ('ISO-8859-7');
insert into mi_charset (charset) values ('ISO-8859-8');
insert into mi_charset (charset) values ('ISO-8859-9');
insert into mi_charset (charset) values ('ISO-8859-10');
insert into mi_charset (charset) values ('ISO-8859-11');
insert into mi_charset (charset) values ('ISO-8859-12');
insert into mi_charset (charset) values ('ISO-8859-13');
insert into mi_charset (charset) values ('ISO-8859-14');
insert into mi_charset (charset) values ('ISO-8859-15');
insert into mi_charset (charset) values ('UTF-7');
insert into mi_charset (charset) values ('UTF-8');
insert into mi_charset (charset) values ('UTF-16');

----------------------------------------------------------------
-- create top level etp doc
create function tmp_0 () returns integer as '
declare
	v_cid		t_object;
	v_vid		t_object;
begin

	-- create new content
	select into v_cid mi_g_object__new_type( ''etp/content'' );

	insert into mi_content (content_id, content_type, mime_type )
	       values (v_cid, ''etp'', ''text/html'' );

	-- create new version
	select into v_vid mi_g_object__new_type( ''generic/version'' );

	insert into mi_content_version (version_id, content_id, summary, content)
	       values (v_vid, v_cid, ''Doc Root'', '''');

	return 1;
end;' language 'plpgsql';

select tmp_0();
drop function tmp_0();

