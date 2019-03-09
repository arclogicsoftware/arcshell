function test_file_setup {
   touch "${_fileTestFile}"
   echo "${_fileTestFile}" | assert -f
}

function test_function_setup {
   :
}





































function test_function_teardown {
   :
}

function test_file_teardown {
   rm "${_fileTestFile}" 2> /dev/null
   echo "${_fileTestFile}" | assert ! -f
}

