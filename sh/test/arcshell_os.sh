function test_os_return_load {
   num_is_whole $(os_return_load -w) && pass_test || fail_test 
   num_is_num $(os_return_load) && pass_test || fail_test 
   ! num_is_whole $(os_return_load) && pass_test || fail_test 
}

function test_os_return_os_type {
   os_return_os_type | assert_match "LINUX|AIX|HP-UX|SUNOS"
}

function test_os_disks {
   os_disks 2>&1 >/dev/null | assert -l 0
   os_disks | grep "\/" | assert -l ">0"
}

function test_os_is_process_id_process_name_running {
   os_is_process_id_process_name_running $$ && pass_test || fail_test
   ! os_is_process_id_process_name_running 123456789 && pass_test || fail_test
   ! os_is_process_id_process_name_running 0 && pass_test || fail_test
}

function test_os_get_process_count {
   os_create_process "BUZZ" 10 2
   #debug_set_output 2
   #debug_set_level 3
   # Solaris requires a little time for the counts to register.
   assert_sleep 4
   os_get_process_count "BUZZ" | assert "2" 
   #debug_set_output 0
   os_create_process "FIZZ" 5 1
   # Solaris requires a little time for the counts to register.
   assert_sleep 2
   os_get_process_count "FIZZ" | assert "1" 
   assert_sleep 6
   os_get_process_count "FIZZ" | assert "0" 
}

function test_os_create_process {
   os_create_process "SPACEX" 5 1
   sleep 1
   os_get_process_count "SPACEX" | assert 1 
   sleep 5
   os_get_process_count "SPACEX" | assert 0
}

function test__os_get_any_shell_but_bash {
   _os_get_any_shell_but_bash | assert -f
}

