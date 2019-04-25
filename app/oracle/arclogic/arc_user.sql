define username="&1"

grant create session to &username;
grant alter session to &username;
grant dba to &username;
grant select any table to &username;
grant execute any procedure to &username;
grant analyze any to &username;
grant select any table to &username;
grant alter any table to &username;
grant alter any index to &username;
grant execute on dbms_system to &username;
grant execute on dbms_lock to &username;
grant select on gv_$database to &username;
grant select on gv_$instance to &username;
grant select on gv_$session to &username;
grant select on gv_$system_event to &username;
grant select on gv_$waitstat to &username;
grant select on gv_$sysstat to &username;
grant select on dba_free_space to &username;
grant select on dba_data_files to &username;
grant select on dba_tables to &username;
grant select on dba_segments to &username;
grant select on dba_indexes to &username;
grant select any dictionary to &username;
grant create any directory to &username;
grant create any synonym to &username;
grant create public synonym to &username;
grant alter system to &username;
grant create user to &username;
grant alter user to &username;
grant drop user to &username;
grant create table to &username;
grant create role to &username;
grant grant any object privilege to &username;
grant drop any directory to &username;
grant create database link to &username;
grant EXEMPT ACCESS POLICY to &username;
grant drop any table to &username;
grant execute on dbms_system to &username;
grant execute on dbms_lock to &username;
grant delete any table to &username;