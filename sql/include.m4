
define(`index', INDEX)dnl
define(`t_object',   `varchar')dnl
define(`t_type',     `integer')dnl
define(`refs',       t_object `references $1 on update cascade')dnl
define(`ref_object', refs(mi_g_object))dnl
define(`subclass',   t_object primary key references $1 on update cascade on delete cascade)dnl
define(`isa_object', subclass(mi_g_object))dnl
