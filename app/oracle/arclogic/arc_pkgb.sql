create or replace package body arclogic as

function secs_between_timestamps (time_start in timestamp, time_end in timestamp) return number is
   -- http://caffeineinduced.wordpress.com/2006/11/21/oracle-derence-between-two-timestamps-in-seconds/
   total_secs number;
   d interval day(9) to second(6);
begin
   d := time_end - time_start;
   total_secs := abs(extract(second from d) + extract(minute from d)*60 + extract(hour from d)*60*60 + extract(day from d)*24*60*60);
   return total_secs;
end;

function secs_since_timestamp (time_stamp timestamp) return number is
   now         timestamp;
   total_secs  number;
   d           interval day(9) to second(6);
begin
   now := cast(sysdate as timestamp);
   d := now - time_stamp;
   total_secs := abs(extract(second from d) + extract(minute from d)*60 + extract(hour from d)*60*60 + extract(day from d)*24*60*60);
   return total_secs;
end;

function str_to_key_str (str in varchar2) return varchar2 is
   new_str varchar2(1000);
begin
   new_str := regexp_replace(str, '[^A-Z|a-z|0-9]', '_');
   return new_str;
exception
   when others then
      raise;
end;

   
end;
/
