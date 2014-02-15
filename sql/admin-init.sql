-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Created: 2003-Nov-12 11:30 (EST)
-- Function: 
--
-- $Id: admin-init.sql,v 1.2 2010/01/15 18:13:18 jaw Exp $

insert into mi_sys_config (param, descr, type, value) values
       ('show_source', 'include show source link on web pages', 'bool', 1),
       ('show_argus',  'include argus summary on web pages', 'bool', 1),
       ('error_email', 'address to email errors to', 'text', NULL),

        ('sect_ipdb',  'enable IPDB',          'bool', 0),
        ('sect_forum', 'enable forums',        'bool', 1),
        ('sect_tkt',   'enable ticket system', 'bool', 1),
        ('sect_eqmt',  'enable eqmt system',   'bool', 1);




