function test_debug_truncate {
   :
}

function test_debug_start {
   _g_debug_session_level=
   debug_start
   echo ${_g_debug_session_level} | assert 3 "Debug level defaults to 3 if not defined."
   debug1 "debug_session_test"
   debug_dump | assert_match "debug_session_test" "Dump output should contain the string from the debug call."
   debug_dump | assert_nomatch "debug_session_test" "Dump output should no longer contain the string we just dumped."
   debug_start 1
   debug2 "debug_session_test"
   debug_dump | assert_nomatch "debug_session_test" "Debug level 2 call should not be in our dump output."
}

function test_debug_dump {
   debug_start 3
   debug1 "debug_session_test1"
   debug2 "debug_session_test2"
   debug3 "debug_session_test3"
   debug_dump | egrep "test1|test2|test3" | assert -l 3
   debug_dump | egrep "test1|test2|test3" | assert -l 0
}

function test_debug_stop {
   debug_start
   debug1 "foo"
   debug_dump | wc -l | assert ">0"
   debug_stop
   debug1 "foo"
   debug_dump | assert -l 0
}

function test__debug {
   :
}

function test__debugd {
   :
}

function test_debug0 {
   :
}

function test_debug1 {
   cp /dev/null "${_g_debug_file}"
   _g_debug_level=1
   _g_debug_session_level=0
   debug1 "mango"
   cat "${_g_debug_file}" | grep "mango" | assert_match "mango" "Debug file should contain the string we are looking for."
   debug2 "pear"
   cat "${_g_debug_file}" | grep "pear" | assert_nomatch "pear" "Debug file should not contain the string we are looking for."
}

function test_debug2 {
   cp /dev/null "${_g_debug_file}"
   _g_debug_level=2
   _g_debug_session_level=0
   debug2 "mango"
   cat "${_g_debug_file}" | grep "mango" | assert_match "mango" "Debug file should contain the string we are looking for."
   debug3 "pear"
   cat "${_g_debug_file}" | grep "pear" | assert_nomatch "pear" "Debug file should not contain the string we are looking for."
}

function test_debug3 {
   cp /dev/null "${_g_debug_file}"
   _g_debug_level=3
   _g_debug_session_level=0
   debug3 "mango"
   cat "${_g_debug_file}" | grep "mango" | assert_match "mango" "Debug file should contain the string we are looking for."
   debug1 "pear"
   cat "${_g_debug_file}" | grep "pear" | assert_match "pear" "Debug file should contain the string we are looking for."
}

function test_debugd0 {
   pass_test
}

function test_debugd1 {
   pass_test
}

function test_debugd2 {
   pass_test
}

function test_debugd3 {
   pass_test
}

function test_debug_get {
   _g_debug_level=1
   debug1 "H2O"
   debug1 "CO2"
   debug_get 1 | grep "CO2" | assert -l 1
}

function test__debugWrite {
   _g_debug_level=3
   _g_debug_session_level=0
   debugd1 < <(echo "Z1")
   echo "Z2" | debugd2
   echo "Z3" | debugd3
   cat "${_g_debug_file}" | egrep "Z1|Z2|Z3" | assert -l 3 "Debug detail calls write to log file."
   cp /dev/null "${_g_debug_file}"
   _g_debug_level=0
   _g_debug_session_level=0
   debugd1 < <(echo "Z1")
   echo "Z2" | debugd2
   echo "Z3" | debugd3
   cat "${_g_debug_file}" | egrep "Z1|Z2|Z3" | assert -l 0 "Debug detail calls do not write to log file."
}

