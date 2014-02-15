

SQL =	obj-dm.sql     obj-fnc.sql     obj-init.sql \
	generic-dm.sql generic-fnc.sql generic-init.sql \
	task-dm.sql    task-fnc.sql    task-init.sql \
	search-dm.sql  search-fnc.sql  search-init.sql \
	users-dm.sql   users-fnc.sql   users-init.sql \
	tkt-dm.sql     tkt-fnc.sql     tkt-init.sql \
	eqmt-dm.sql    eqmt-fnc.sql    eqmt-init.sql \
	ckt-dm.sql     ckt-fnc.sql     ckt-init.sql \
	forums-dm.sql  forums-fnc.sql  forums-init.sql \
	ipdb-dm.sql    ipdb-fnc.sql    ipdb-init.sql \
	bkmk-dm.sql    bkmk-fnc.sql    bkmk-init.sql \
	admin-dm.sql                   admin-init.sql \
	test.sql


create:
	m4 include.m4 $(SQL) | ../bin/createdb

createdb:
	createuser -S -d -R -l -P -U postgres rambam
	createdb $(SQLARGS) -E UTF-8 $(DB)
	createlang $(SQLARGS) -U pgsql plpgsql $(DB)

drop:
	m4 include.m4 $(SQL) | ../bin/dropdb

