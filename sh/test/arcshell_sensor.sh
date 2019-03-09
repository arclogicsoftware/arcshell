function test_file_setup {
   touch "${_sensorTestFile}"
   echo "${_sensorTestFile}" | assert -f
}

function test_sensor_check {
   sensor_delete_sensor "foo" && pass_test || fail_test 
   ! sensor_exists "foo" && pass_test || fail_test 
   ! echo "x" | sensor_check "foo" && pass_test || fail_test
   sensor_exists "foo" && pass_test || fail_test 
   sensor_get_fail_count "foo" | assert 0
   sensor_return_sensor_value "foo" | assert "x"
   sensor_passed "foo" && pass_test || fail_test 
   echo "y" | sensor_check -tags "tag1 tag2" "foo" && pass_test || fail_test 
   sensor_failed "foo" && pass_test || fail_test 
   sensor_get_fail_count "foo" | assert 1
   sensor_get_last_detected_times "foo" 5 | assert -l 1
   sensor_delete_sensor_group "foo" && pass_test || fail_test 
   ! sensor_exists -g "foo" "bar" && pass_test || fail_test 
   ! echo "x" | sensor_check -g "foo" "bar" && pass_test || fail_test 
   sensor_exists -g "foo" "bar" && pass_test || fail_test 
   sensor_passed -g "foo" "bar" && pass_test || fail_test "New sensor should pass."
   echo "y" | sensor_check -g "foo" "bar" && pass_test || fail_test 
   sensor_failed -g "foo" "bar" && pass_test || fail_test 
   sensor_get_last_detected_times -g "foo" "bar" 5 | assert -l 1
   sensor_get_last_diff -g "foo" "bar" | assert -l ">=3"
   sensor_delete_sensor_group "foo" && pass_test || fail_test 
   ! echo "x" | sensor_check -g "foo" -t 2 "bar" && pass_test || fail_test
   ! echo "y" | sensor_check -g "foo" -t 2 "bar" && pass_test || fail_test  
   sensor_is_failing -g "foo" "bar" && pass_test || fail_test 
   echo "y" | sensor_check -g "foo" -t 2 "bar" && pass_test || fail_test 
   sensor_failed -g "foo" "bar" && pass_test || fail_test  
}

function test_sensor {
   _sensorListStatuses | assert -l 3 "There are more than 3 sensor statuses defined."
   sensor_delete_sensor "foo" && pass_test || fail_test 
   echo "x" | sensor 2>&1 >/dev/null | assert_match "ERROR" "Missing key should throw error."
   echo "x" | sensor "foo" | assert -z "New sensors should return null."
   echo "x" | sensor "foo" | assert -z "Sensors should return null when nothing changes."
   echo "z" | sensor "foo" | wc -l | assert ">0" "Changing a sensor value should return output."
   sensor_get_last_diff "foo" | wc -l | assert ">0" "Results of last change should be referencable."
   echo "z" | sensor "foo" | assert -z "Sensor should now be set to 'z' and sensing 'z' should not return a value."
   sensor_get_last_diff "foo" | assert -z "Results of last change should be cleared."
   sensor_delete_sensor "foo"
   echo "z" | sensor -try 3 "foo" | assert -z 
   echo "x" | sensor -try 3 "foo" | assert -z
   echo "x" | sensor -try 3 "foo" | assert -z
   echo "x" | sensor -try 3 "foo" | wc -l | assert ">0" "Third try should trigger the sensor."
   echo "x" | sensor -try 3 "foo" | assert -z
   echo "x" | sensor -try 3 "foo" | assert -z
   echo "x" | sensor -try 3 "foo" | assert -z
   echo "x" | sensor -try 3 "foo" | assert -z
   echo "z" | sensor -try 3 "foo" | assert -z
   echo "z" | sensor -try 3 "foo" | assert -z
   echo "z" | sensor -try 3 "foo" | wc -l | assert ">0" ""
   echo "z" | sensor -try 3 "foo" | assert -z
   echo "z" | sensor -try 3 "foo" | assert -z
   echo "z" | sensor -try 3 "foo" | assert -z
   echo "x" | sensor -try 3 "foo" | assert -z
   echo "a" | sensor -try 3 "foo" | assert -z
   echo "z" | sensor -try 3 "foo" | assert -z
   echo "a" | sensor -try 3 "foo" | assert -z
   echo "b" | sensor -try 3 "foo" | assert -z
   echo "c" | sensor -try 3 "foo" | wc -l | assert ">0"

   sensor_delete_sensor "foo"

   (
   cat <<EOF
a
b
c
EOF
   ) > "${_sensorTestFile}1"

   (
   cat <<EOF
a
b
c
d
EOF
   ) > "${_sensorTestFile}2"

   cat "${_sensorTestFile}1" | sensor -new "foo" | assert -z
   cat "${_sensorTestFile}1" | sensor -new "foo" | assert -z
   cat "${_sensorTestFile}2" | sensor -new "foo" | wc -l | assert ">0"

   cat "${_sensorTestFile}1" | sensor -new "foo" | assert -z

   sensor_delete_sensor "foo"
   cat "${_sensorTestFile}1" | sensor -try 2 -new "foo" | assert -z
   cat "${_sensorTestFile}2" | sensor -try 2 -new "foo" | assert -z
   cat "${_sensorTestFile}2" | sensor -try 2 -new "foo" | wc -l | assert ">0"

   sensor_delete_sensor "foo"
   cat "${_sensorTestFile}1" | sensor -try 2 -new "foo" | assert -z
   cat "${_sensorTestFile}2" | sensor -try 2 -new "foo" | assert -z
   cat "${_sensorTestFile}1" | sensor -try 2 -new "foo" | assert -z
   cat "${_sensorTestFile}2" | sensor -try 2 -new "foo" | assert -z
   cat "${_sensorTestFile}2" | sensor -try 2 -new "foo" | wc -l | assert ">0"
   cat "${_sensorTestFile}1" | sensor -try 2 -new "foo" | assert -z
   cat "${_sensorTestFile}1" | sensor -try 2 -new "foo" | assert -z
   cat "${_sensorTestFile}1" | sensor -try 2 -new "foo" | assert -z

   sensor_delete_sensor "foo"
   echo "x" | sensor "foo"
   echo "z" | sensor "foo" 1>/dev/null  && pass_test || fail_test
   # $(echo "z" | sensor -silent "foo") && fail_test || pass_test
   ! echo "z" | sensor "foo" 1>/dev/null && pass_test || fail_test

}

function test_sensor_exists {
   :
}

function test_sensor_return_sensor_value {
   :
}

function test_sensor_get_sensor_status {
   :
}

function test_sensor_delete_sensor {
   :
}  

function test_sensor_passed {
   :
}

function test_sensor_is_failing {
   :
}

function test_sensor_failed {
   :
}                     

function test_sensor_delete_sensor_group {
   :
}

function test_sensor_get_last_detected_times {
   :
}

function test_sensor_list_sensors {
   :
}

function test_file_teardown {
   rm "${_sensorTestFile}"* 2> /dev/null
   echo "${_sensorTestFile}" | assert ! -f
}

