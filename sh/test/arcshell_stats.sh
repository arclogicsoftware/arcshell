function test_file_setup {
   __setupArcShellStats
}

function test_stats_read {
   echo "bar|10" | stats_read "foo" && pass_test || fail_test 
   #ls "${_statsDir}/tmp/"
   assert_sleep 5
   echo "bar|20" | stats_read "foo" && pass_test || fail_test 
   #ls "${_statsDir}/tmp/"
}

