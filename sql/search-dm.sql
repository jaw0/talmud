-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Date: 2003-Oct-02 18:34 (EDT)
-- Function: 
--
-- $Id: search-dm.sql,v 1.5 2010/01/15 18:13:22 jaw Exp $

create table mi_search_index (
       word		  varchar(64)		not null,
       object		  ref_object		on delete cascade,
       score		  integer		default 1,

       unique(word, object)
);

create index mi_search_index_word_idx   on mi_search_index(word);
create index mi_search_index_object_idx on mi_search_index(object);
