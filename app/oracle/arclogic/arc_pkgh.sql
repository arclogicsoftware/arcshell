create or replace package arclogic as
   function secs_between_timestamps (time_start in timestamp, time_end in timestamp) return number;
   function secs_since_timestamp(time_stamp timestamp) return number;
   function str_to_key_str (str in varchar2) return varchar2;
end;
/

