

select 'FAIL: Name generator should return one row.' arc_name_generator from dual
 where 1!=(select count(*) from name_generator where name like '%_%_%');

select 'FAIL: Something is wrong with here.' str_to_skey_str 
  from dual
 where '1bar___________foo______________bin9'!=(
    select arcshell.str_to_key_str('1bar!@#$%^\&*()foo{}[]\/?><,.";:bin9') x from dual);
    
    
  
