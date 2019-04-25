
-- Some version of this probably comes from Steve Adams of Ixora fame.
-- as well as plenty of other things here.
create or replace view locked_objects as (
select session_id,
       oracle_username
,      object_name
,      decode(a.locked_mode,
              0, 'None',           /* Mon Lock equivalent */
              1, 'Null',           /* N */
              2, 'Row-S (SS)',     /* L */
              3, 'Row-X (SX)',     /* R */
              4, 'Share',          /* S */
              5, 'S/Row-X (SSX)',  /* C */
              6, 'Exclusive',      /* X */
       to_char(a.locked_mode)) mode_held
   from gv$locked_object a
   ,    dba_objects b
  where a.object_id = b.object_id)
/

create or replace view lockers as (
select /*+ ordered */
  l.type || '-' || l.id1 || '-' || l.id2  locked_resource,
  nvl(b.name, lpad(to_char(l.sid), 4)) sid, l.inst_id,
  decode(
    l.lmode,
    1, '      N',
    2, '     SS',
    3, '     SX',
    4, '      S',
    5, '    SSX',
    6, '      X'
  )  holding,
  decode(
    l.request,
    1, '      N',
    2, '     SS',
    3, '     SX',
    4, '      S',
    5, '    SSX',
    6, '      X'
  )  wanting,
  l.ctime  seconds
from
  sys.gv_$lock l,
  sys.gv_$session s,
  sys.gv_$bgprocess b
where
  s.inst_id = l.inst_id and
  s.sid = l.sid and
  -- Don't monitor locks from data pump, triggers many false alarms.
  s.module not like '%Data Pump%' and
  b.paddr (+) = s.paddr and
  b.inst_id (+) = s.inst_id and
  l.type not in ('MR','TS','RT','XR','CF','RS','CO','AE','BR') and
  nvl(b.name, lpad(to_char(l.sid), 4)) not in ('CKPT','LGWR','SMON','VKRM','DBRM','DBW0','MMON'));

create or replace view name_generator as 
   select listagg(str, '_') within group (order by str) as name from (
   select str from (
   select distinct str from (
   with data as (select table_name str from dict where table_name not like '%$%')
   select trim(column_value) str from data, xmltable(('"' || replace(str, '_', '","') || '"')))
   order by dbms_random.value)
   where rownum <= 3) 
/

create or replace view lock_time as (
 select nvl(sum(seconds),0) value
   from lockers);
