function test_num_random {
   num_random 1 | assert "<2"
   num_random 2 3 | assert ">0"
   num_random 9999999 9999999 | assert 9999999
   num_random | assert 0 "Everything should default to zero if no argments are provided."
   ! num_random -1 2> /dev/null && pass_test || fail_test "Negative numbers not allowed. Should return false."
   num_random 0 -1 2>&1 | assert_match "ERROR" "Error message should be reported for negative numbers."
}

function test_num_round_to_multiple_of {
   num_round_to_multiple_of 0 15 | assert 0
   num_round_to_multiple_of 7 15 | assert 0
   num_round_to_multiple_of 8 15 | assert 15
   num_round_to_multiple_of 57 15 | assert 60
   num_round_to_multiple_of 11 20 | assert 20
   num_round_to_multiple_of 99 1000 | assert 0
   num_round_to_multiple_of 77777777 10000000 | assert 80000000
   num_round_to_multiple_of .7 2 | assert 0
   num_round_to_multiple_of .7 1 | assert 1
   # Bug fixed 10/11/2018, needed >= not > in final if then else.
   #assert_banner "BUG: Expected return value 15, not 0." 
   num_round_to_multiple_of 7.5 15 | assert 15 "7.5 should round to 15."
   # This begins passing at 7.65. 
   num_round_to_multiple_of 7.65 15 | assert 15 "See bug." 
   num_round_to_multiple_of 213 424 | assert 424 "BUG: Should round to 424."
   # This does not work with negative numbers.
   # @todo
   # Decimal in second positon does not work at this time.
   # num_round_to_multiple_of .2 .5 | assert 1
}

function test_num_floor {
   num_floor -1.2 | assert "-1"
   num_floor -.2 | assert "0"
   num_floor 1.2 | assert "1"
   num_floor 0.2 | assert "0"
   num_floor 1 | assert "1"
   num_floor .2 | assert "0"
   num_floor .9 | assert "0"
   num_floor 0.00 | assert "0"
   echo 9.9 | num_floor -stdin | assert 9
   echo 0.01 | num_floor -stdin | assert 0
}

function test_num_is_whole {
   $(num_is_whole 0) & pass_test || fail_test
   $(num_is_whole 2) & pass_test || fail_test
   ! $(num_is_whole 1.2) & pass_test || fail_test
   ! $(num_is_whole 2.0) & pass_test || fail_test
}

function test_num_is_even {
   $(num_is_even 2) && pass_test || fail_test
   $(num_is_even 0) && pass_test || fail_test
   ! $(num_is_even 3) && pass_test || fail_test
   ! $(num_is_even 2.1) && pass_test || fail_test
}

function test_num_is_odd {
   $(num_is_odd 3) && pass_test || fail_test
   ! $(num_is_odd 0) && pass_test || fail_test
   ! $(num_is_odd 2) && pass_test || fail_test
   ! $(num_is_odd 3.1) && pass_test || fail_test
}

function test_num_is_gt {
   $(num_is_gt 5 4) && pass_test || fail_test
   $(num_is_gt .05 .01) && pass_test || fail_test
   $(num_is_gt .01 .01) && fail_test || pass_test
   $(num_is_gt 999 999999999) && fail_test || pass_test
}

function test_num_range {
   num_range 1 3 | egrep "1|2|3" | assert -l 3
   num_range 1 3 | head -1 | assert 1
   num_range -1 1 | head -1 | assert "-1"
   num_range 3 1 | egrep "1|2|3" | assert -l 3
   num_range 3 1 | head -1 | assert 3
   num_range 1 -1 | tail -1 | assert "-1"
}

function test_num_max {
   num_max 34 23 49 0 | assert 49
   num_max .1 .5 .2 .0 | assert .5
   num_max .1, .5 .2 .0 | assert .5
   num_max .1 .5 .2 .0 .96 .95 | assert .96
   echo .1 .5 .2 .0 | str_split_line " " | num_max | assert .5
   echo "" | num_max | assert -z
   #num_max 2>&1 > /dev/null | wc -l | assert 0
}

function test_num_min {
   num_min 34 23 49 0 | assert 0
   num_min .1 .5 .2 | assert .1
   num_min .1 .5 .2 | assert .1
   num_min .1 .5 .2 .0 .96 .95 | assert .0
   echo .1 .5 .2 | str_split_line " " | num_min | assert .1
   echo "" | num_min | assert -z
   #num_min 2>&1 > /dev/null | assert -z
}

function test_num_sum {
   printf "1000000.25\n1000000.25\n" | num_sum -d 1 -stdin | assert 2000000.5
   num_sum -d 2 2 2.25 | assert 4.25
   num_sum -d 1 2 2.25 | assert 4.2
   num_sum -d 1 2 2.25 | assert 4.2 
   # Note above total of 4.25 does not round up to 4.3.
   # Below does round up.
   num_sum -d 1 2 2.26 | assert 4.3
   num_sum 2 2.26 | assert 4
}

function test_num_avg {
   num_avg 2 2 2 | assert 2 
   printf "2\n2\n2\n" | num_avg - | assert 2
   num_avg 2 4 | assert 3
   printf "2\n4\n" | num_avg - | assert 3
   num_avg 1 2 | assert 1.5
   printf "1\n2\n" | num_avg - | assert 1.5
}

function test_num_stddev {
   :
}

function test_num_is_num {
   typeset x
   ! $(num_is_num) && pass_test || fail_test
   for x in 1 1.5 100000000.5 1.123456789 -100.5 .5 0.5 -.05; do
      $(num_is_num ${x}) && pass_test || fail_test
   done
   for x in "A" "100A" "++100.5" "--100.5" "1.1.1"; do
      ! $(num_is_num ${x}) && pass_test || fail_test
   done
}

function test_num_raise_is_not_a_number {
   num_raise_is_not_a_number "unittesting" 2 && fail_test || pass_test 
   num_raise_is_not_a_number "unittesting" "foo" 2>&1 assert_match "ERROR" 
   num_raise_is_not_a_number "unittesting" "foo" 2> /dev/null && pass_test || fail_test 
}

function test_num_correct_for_octal_error {
   echo "0001" | num_correct_for_octal_error -stdin | assert "1"
   echo "0001.00" | num_correct_for_octal_error -stdin | assert "1.00"
   echo "0000.01" | num_correct_for_octal_error -stdin | assert "0.01"
   echo "0.0" | num_correct_for_octal_error -stdin | assert "0.0"
   echo ".0" | num_correct_for_octal_error -stdin | assert "0.0"
   echo "1.000" | num_correct_for_octal_error -stdin | assert "1.000"
   echo "00" | num_correct_for_octal_error -stdin | assert "0"
}

function test_num_is_gt_zero {
   $(num_is_gt_zero 01) && pass_test || fail_test
   ! $(num_is_gt_zero 0) && pass_test || fail_test
   $(num_is_gt_zero .1) && pass_test || fail_test
   $(num_is_gt_zero 0.1) && pass_test || fail_test
   $(num_is_gt_zero 999999999) && pass_test || fail_test
}

function test_num_is_zero {
   $(num_is_zero 0) && pass_test || fail_test
   $(num_is_zero 0.0) && pass_test || fail_test
   $(num_is_zero 0) && pass_test || fail_test
   ! $(num_is_zero 01) && pass_test || fail_test
   ! $(num_is_zero 0.9) && pass_test || fail_test
}

