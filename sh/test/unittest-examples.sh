function test_how_to_use_pass_and_fail_test {
   (( 1 == 1 )) && pass_test || fail_test 
   (( 1 < 0 )) && fail_test "1 should not be less than 0" || pass_test 
   [[ -d "/tmp" ]] && pass_test || fail_test "/tmp directory doesn't exist"
}

function test_how_to_test_for_a_number {
   echo 1 | assert 1 "1 should equal 1"
   echo 1.1 | assert 1.1 "1.1 should equalt 1.1"
   assert_true "(( 1 == 1 ))" "1 should still equal 1"
}

function test_how_to_test_for_a_string {
   echo "foo" | assert "foo"
   assert_true "[[ "foo" == "foo" ]]" "foo should equal foo"
   echo "foo" | assert_match "^foo$" "foo should still equal foo"
   echo "foo" | grep "^foo$" | assert -l 1
}

function test_for_number_of_lines {
   echo "foo" | assert -l 1 "one line expected"
   echo "foo" | wc -l | assert 1 "one line expected"
   assert_true "(( $(echo "foo" | wc -l) == 1 ))" "1 line expected"
}

function test_for_a_file {
   ls /etc/passwd | assert -f "this file should exist"
   echo "/etc/passwd" | assert -f "this file should exist"
   assert_true "[[ -f /etc/passwd ]]" "this file should exist"
}

function test_for_a_dir {
   echo "/etc" | assert -d "this dir should exist"
   assert_true "[[ -d /etc ]]" "this dir should exist"
   assert_false "[[ ! -d /etc ]]" "this dir should exist"
}

function test_for_non_null_value {
   echo "foo" | assert -n "this value should not be null"
   assert_true "[[ -n "foo" ]]" "this value should not be null"
   echo "foo" | assert ! -z "this value shoudl not be null"
}

function test_for_null_value {
   typeset x
   cat /dev/null | assert -z "this value should be null"
   x=
   assert_true "[[ -z \"${x}\" ]]" "this value should be null"
   cat /dev/null | assert ! -n "this value shoudl be null"
}

function test_regex_match {
   echo "foo" | assert_match "foo" "foo should match foo"
}

function test_regex_no_match {
   echo "foo" | assert_nomatch "bar" "foo should not match bar"
}

function test_is_ksh {
   boot_is_valid_ksh && pass_test || fail_test 
}

function test_is_bash {
   boot_is_valid_bash && pass_test || fail_test 
}

