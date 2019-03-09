function test_file_setup {
   rm -rf "${arcTmpDir}/pkg_test" 2> /dev/null 
   cp -rp "${arcHome}/sh/core" "${arcTmpDir}/pkg_test"
   pkg_dir -saveto "${arcTmpDir}" "${arcTmpDir}/pkg_test"
}

function test_pkg_set {
   pkg_set "${arcTmpDir}/pkg_test.tar.gz" && pass_test || fail_test 
   echo "${_g_pkgWorkingFile}" | assert -f
   pkg_set "${arcTmpDir}/xpkg_test.tar.gz" && fail_test || pass_test 
   echo "${_g_pkgWorkingFile:-}" | assert -z
}

function test_pkg_dir {
   pkg_dir "${arcTmpDir}/pkg_test" && pass_test || fail_test 
}

function test_pkg_ssh_copy {
   :
}

function test_pkg_list {
   :
}

function test_package_end {
   rm -rf "${arcTmpDir}/pkg_test" 2> /dev/null 
   rm "${arcHome}/pkg_test.tar.gz"
}

