function test_assert {
   _g_testing_self=1
   echo "/tmp$$" | assert ! -d && pass_test || fail_test 
   echo 10 | assert ">= 9" && pass_test || fail_test 
   echo 0 | assert "=0" && pass_test || fail_test 
   echo 0 | assert "<1" && pass_test || fail_test 
   echo 1 | assert ">1" "Should be > 1!" && fail_test || pass_test 
   echo 1 | assert "=0" && fail_test || pass_test 
   echo 1 | assert "<1" && fail_test || pass_test 
   echo 0 | assert "!>-1" && fail_test || pass_test 
   echo 0 | assert "!=0" && fail_test || pass_test 
   echo 0 | assert "!<1" && fail_test || pass_test 
   echo 1 | assert "!>1" && pass_test || fail_test 
   echo 1 | assert "!=0" && pass_test || fail_test 
   echo 1 | assert "!<1" && pass_test || fail_test 
   echo "foo" | assert " foo" && fail_test || pass_test 
   echo "foo" | assert "!bar" && pass_test || fail_test 
   echo "foo" | assert "=foo" && pass_test || fail_test 
   echo "foo" | assert "!=bar" && pass_test || fail_test 
   echo "foo" | assert "!foo" && fail_test || pass_test 
   echo "foo" | assert "bar" && fail_test || pass_test 
   echo "foo" | assert "=bar" && fail_test || pass_test 
   echo "foo" | assert "!=bar" && pass_test || fail_test 
   _g_testing_self=0
}

function test_assert_true {
   _g_testing_self=1
   assert_true "(( 1 ))" && pass_test || fail_test 
   assert_true "(( 0 ))" && fail_test || pass_test 
   assert_true "(( 1 == 1 ))" && pass_test || fail_test 
   assert_true "(( 1 != 0 ))" && pass_test || fail_test 
   assert_true "[[ -f "/etc/passwd" ]]" && pass_test || fail_test 
   assert_true "[[ ! -f "/etc/passwd" ]]" && fail_test  || pass_test 
   assert_true "grep "${LOGNAME}" /etc/passwd 1> /dev/null" && pass_test || fail_test 
   assert_true "[[ "${LOGNAME}" == "${LOGNAME}" ]]" && pass_test || fail_test 
   _g_testing_self=0
}

function test_assert_false {
   _g_testing_self=1
   assert_false "(( 1 ))" && fail_test || pass_test 
   assert_false "(( 0 ))" && pass_test || fail_test 
   assert_false "(( 1 == 1 ))" && fail_test || pass_test 
   assert_false "(( 1 != 0 ))" && fail_test || pass_test 
   assert_false "[[ -f "/etc/passwd" ]]" && fail_test || pass_test 
   assert_false "[[ ! -f "/etc/passwd" ]]" && pass_test || fail_test 
   assert_false "grep "${LOGNAME}" /etc/passwd 1> /dev/null" && fail_test || pass_test 
   assert_false "[[ "${LOGNAME}" == "${LOGNAME}" ]]" && fail_test || pass_test 
   _g_testing_self=0
}

function test_assert_sleep {
   _g_testing_self=1
   assert_sleep 5 && pass_test || fail_test
   _g_testing_self=0
}

function test_assert_banner {
   :
}

function test__assertIsFile {
   _g_testing_self=1
   _assertIsFile "/etc/passwd" && pass_test || fail_test 
   _assertIsFile "/tmp" && fail_test || pass_test 
   _g_testing_self=0
}

function test__assertIsNotFile {
   _g_testing_self=1
   _assertIsNotFile "/etc/passwd" && fail_test || pass_test 
   _assertIsNotFile "/tmp" && pass_test || fail_test 
   _g_testing_self=0
}

function test__assertIsDir {
   _g_testing_self=1
   _assertIsDir "/etc/passwd" && fail_test || pass_test 
   _assertIsDir "/tmp" && pass_test || fail_test 
   _g_testing_self=0
}

function test__assertIsNotDir {
   _g_testing_self=1
   _assertIsNotDir "/etc/passwd" && pass_test || fail_test 
   _assertIsNotDir "/tmp" && fail_test || pass_test 
   _g_testing_self=0
}

function test__assertIsNotNull {
   _g_testing_self=1
   _assertIsNotNull "x" && pass_test || fail_test 
   _assertIsNotNull "" && fail_test || pass_test 
   _g_testing_self=0
}

function test__assertIsNull {
   _g_testing_self=1
   _assertIsNull "x" && fail_test || pass_test 
   _assertIsNull "" && pass_test || fail_test 
   _g_testing_self=0
}

function test_assert_match {
   _g_testing_self=1
   echo "foo" | assert_match "foo" && pass_test || fail_test 
   echo "foo" | assert_match "bar" && fail_test || pass_test 
   _g_testing_self=0
}

function test_assert_nomatch {
   _g_testing_self=1
   echo "foo" | assert_nomatch "foo" && fail_test || pass_test 
   echo "foo" | assert_nomatch "bar" && pass_test || fail_test 
   _g_testing_self=0
}

