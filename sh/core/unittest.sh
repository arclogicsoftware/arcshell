

# module_name="Unit Testing"
# module_about="A unit test library for bash and korn shells."
# module_version=1
# module_image="list.png"
# copyright_notice="Copyright 2019 Arclogic Software"

# Debug is dumped after every test even if it passes when this is 1.
_g_dump_debug_on_pass=0

# Set this to 1 in your environment to disable all debug dumps.
_g_debug_enabled=1

[[ -z "${arcTmpDir}" ]] && return
_testingDir="${arcTmpDir}/_arcshell_unittest"

mkdir -p "${_testingDir}/data"
mkdir -p "${_testingDir}/log"
_testingTmpDir="${_testingDir}/tmp/$(boot_return_tty_device)"
mkdir -p "${_testingTmpDir}"

_g_test_log="${_g_test_log:-${_testingDir}/log/unittest.log}"
_g_temp_log="${_testingTmpDir}/unittest.tmp}"
_g_test_failure_message=
_g_testing_self=0
_g_tap_format_enabled=0
_g_lint_test=0
_g_test_file="$0"

function __readmeUnittest {
   cat <<EOF
> I Hate Programming. I Hate Programming. I Hate Programming. It works! I Love Programming. - Anonymous

# Unit Testing

**A unit test library for bash and korn shells.**

Build simple, elegant, unit tests for libraries written in shell (bash or ksh). 
EOF
}

function _testingIsDebugLoaded {
   #
   # >>> _testingIsDebugLoaded
   if boot_does_function_exist "debug_start"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _testingDebugStart {
   # Start the debugger.
   # This function integrates the debugger. 
   # >>> _testingDebugStart
   _testingIsDebugLoaded && debug_start 3
}

function _testingDebugStop {
   # Stop the debugger.
   # This function integrates the debugger.
   # >>> _testingDebugStop
   _testingIsDebugLoaded && debug_stop
}

function _testingReturnDebugDump {
   # Dump the current contents of the debugger.
   # >>> _testingReturnDebugDump
   if _testingIsDebugLoaded; then
      stderr_banner "Debug Log"
      debug_dump
   fi
}

function unittest_debug_on {
   # Enable debug dumps if debug is loaded. Defaults to on.
   # >>> unittest_debug_on
   ${arcRequireBoundVariables}
   if _testingIsDebugLoaded; then
      _g_debug_enabled=1
   fi
}

function unittest_debug_off {
   # Disble debug dumpes.
   # >>> unitest_debug_off
   ${arcRequireBoundVariables}
   _g_debug_enabled=0
}

function unittest_dump_debug_on {
   # Enables automatic debug dumps after passing tests.
   # >>> unittest_dump_debug_on
   _g_dump_debug_on_pass=1
}

function unittest_dump_debug_off {
   # Disables automatic debug dumps after passing tests.
   # >>> unittest_dump_debug_off 
   _g_dump_debug_on_pass=0
}

function unittest_header {
   # Define one or more lines to run before running the tests for a file.
   # >>> unittest_header [ -stdin | "header_text" ]
   ${arcRequireBoundVariables}
   if [[ "${1}" == "-stdin" ]]; then
      cat > "${_testingTmpDir}/header.$$"
   else
      echo "${1}" > "${_testingTmpDir}/header.$$"
   fi
}

function _testingReturnHeader {
   # Returns the header text if set.
   # >>> _testingReturnHeader
   [[ -f "${_testingTmpDir}/header.$$" ]] && cat "${_testingTmpDir}/header.$$"
}

function _testingReturnFilePathToSelf {
   # Returns the path to the ````unittest.sh```` file.
   # >>> _testingReturnFilePathToSelf
   if [[ -f "$0" ]] && echo "$0" | grep "unittest.sh" 1> /dev/null; then
      echo "$0"
      ${returnTrue} 
   elif [[ -f "./unittest.sh" ]]; then
      echo "./unittest.sh"
   elif which "unittest.sh" 1> /dev/null; then
      which "unittest.sh"
      ${returnTrue} 
   else 
      _testingThrowError "unittest.sh should be in current directory or \${PATH}."
      ${returnFalse} 
   fi
}

function unittest_test {
   # Run the tests associated with a file. 
   # >>> unittest_test [-tap,-t] [-lint,-l] [-shell,-s "X"] "file" "[regex]"
   # -tap: Return results using Test Anything Protocal.
   # -lint: Runs lint tests instead of normal unit tests..
   # file: Test file. Use full path.
   # regex: Limit tests to those matching ```regex```.
   typeset _testingShellPath _testingExeTestsFile testFile tmpFile regex _testingTargetFileDir hasFileSetup hasFileTeardown
   debug2 "unittest_test: $*"
   ${arcRequireBoundVariables}
   while (( $# > 0)); do
      case "${1}" in
         "-shell"|"-s") shift; _testingShellPath="${1}" ;;
         "-tap"|"-t") _g_tap_format_enabled=1 ;;
         "-lint"|"-l") _g_lint_test=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "unittest" "(( $# <= 2 ))" "$*" && ${returnFalse} 
   _testingTargetFile="${1}"
   regex="${2:-".*"}"
   [[ -z "${_testingShellPath:-}" ]] && _testingShellPath="$(which bash)"
   _testingExeTestsFile="${_testingTmpDir}/tests.$$"
   _testingTargetFileDir="$(dirname "${_testingTargetFile}")"
   file_raise_is_not_full_path "${_testingTargetFile}" && ${returnFalse} 
   if ! _testingReturnFilePathToSelf 1> /dev/null; then
      _testingThrowError "unittest.sh not found: $*: unittest" 
      ${returnFalse} 
   fi
   (
   cat <<EOF
#!${_testingShellPath}

$(_testingReturnHeader)

. $(_testingReturnFilePathToSelf)

EOF
   ) > "${_testingExeTestsFile}"

   tmpFile="$(mktempf)"

   if (( ! ${_g_lint_test} )); then
      hasFileSetup=0
      hasFileTeardown=0
      while read testFile; do 
         echo ". "${testFile}"" >> "${_testingExeTestsFile}"
         if _testingHasFileSetup "${testFile}"; then 
            log_info "${testFile}"
            hasFileSetup=1
         fi
         _testingReturnTestCallBlocks "${testFile}" "${regex}" >> "${tmpFile}"
         if _testingHasFileTeardown "${testFile}"; then 
            hasFileTeardown=1
         fi
      done < <(_testingReturnTestFiles "${_testingTargetFile}")
      if (( ${hasFileSetup} )); then
         log_info "yes!"
         (
         echo ""
         echo "_testingTestFunction=test_file_setup"
         echo "_testingSetTestNum 0"
         echo "test_file_setup"
         cat "${tmpFile}"
         ) > "${tmpFile}.1"
         mv "${tmpFile}.1" "${tmpFile}"
      fi
      if (( ${hasFileTeardown} )); then
         (
         echo ""
         echo "_testingTestFunction=test_file_teardown"
         echo "_testingSetTestNum 0"
         echo "test_file_teardown"
         ) >> "${tmpFile}"
      fi
   else
      if ! grep "^# DoNotLint" "${1}" 1> /dev/null; then
         while read testFile; do 
            echo ". "${testFile}"" >> "${_testingExeTestsFile}"
            _testingReturnTestCallBlocks "${testFile}" "${regex}" >> "${tmpFile}"
         done < <(_testingReturnLintFiles "${_testingTargetFile}")
      fi
   fi

   (
   cat <<EOF

_testingTargetFile="${_testingTargetFile}"
_testingShellPath="${_testingShellPath}"
_testingStartTestRun "${_testingTargetFile}"
$(_loadTest "${_testingTargetFile}")
$(cat "${tmpFile}")
_testingEndTestRun
_saveTest
EOF
   ) >> "${_testingExeTestsFile}"
   # cat "${_testingExeTestsFile}"
   rm "${tmpFile}"
   chmod 700 "${_testingExeTestsFile}"
   "${_testingExeTestsFile}" 
}

function unittest_cleanup {
   # Cleans up header and temporary files after running a series of unit tests.
   # >>> unittest_cleanup 
   ${arcRequireBoundVariables}
   [[ -d "${_testingTmpDir}" ]] && find "${_testingTmpDir}" -type f -exec rm {} \;
}

function _testingReturnTestCallBlocks {
   # Return the block of text which initializes and calls a test function.
   # >>> _testingReturnTestCallBlocks "file" "regex"
   typeset f file function_setup function_teardown regex
   file="${1}"
   regex="${2:-".*"}"
   if _testingHasFunctionSetup "${file}"; then
      function_setup="
_testingTestFunction=test_function_setup
_testingSetTestNum 0
test_function_setup
"
   fi
   if _testingHasFunctionTeardown "${file}"; then
      function_teardown="
_testingTestFunction=test_function_teardown
_testingSetTestNum 0
test_function_teardown
"
   fi
   while read f; do
      cat <<EOF
${function_setup:-}
_testingTestFunction=${f}
_testingSetTestNum 0
${f}
${function_teardown:-}

EOF
   done < <(_testingReturnListOfTestFunctions "${1}" | egrep "${regex}")
}

function _testingDumpDebug {
   # Dump the current debug buffer if it is available and enabled.
   # >>> _testingDumpDebug
   ${arcRequireBoundVariables}
   if _testingIsDebugLoaded && (( ${_g_debug_enabled} )); then
      _testingReturnDebugDump | _testingSTDERR
      _testingDebugStart
   fi
}

function pass_test {
   # Signals a passing test.
   # >>> pass_test 
   ${arcRequireBoundVariables}
   eval "$(_loadTest)"
   if (( ${_g_dump_debug_on_pass} )); then
      _testingDumpDebug
   else
      _testingDumpDebug 2> /dev/null 
   fi
   ((_testingPassCount=_testingPassCount+1))
   ((_testingTestNum=_testingTestNum+1))
   ((_testingTapTestNum=_testingTapTestNum+1))
   if (( ${_g_tap_format_enabled} )); then
      echo "ok ${_testingTapTestNum} ${_testingTestFunction}_${_testingTestNum}"
   else 
      _testingSTDOUT "[ p ]  ${_testingTestFunction}_${_testingTestNum}: ${_testingAssertionText:-"test passed"}"
   fi
   _testingAssertionText=
   _g_test_failure_message=
   _saveTest
   _testingResetTempLog
}

function fail_test {
   # Signals a failing test.
   # >>> fail_test ["test_failure_message"]
   # test_failure_message: Test failure message.
   ${arcRequireBoundVariables}
   if (( $# == 1 )); then
      _g_test_failure_message="${1}"
   fi
   [[ -z "${_g_test_failure_message}" ]] && _g_test_failure_message="${_testingAssertionText:-}"
   eval "$(_loadTest)"
   _testingDumpDebug
   ((_testingFailCount=_testingFailCount+1))
   ((_testingTestNum=_testingTestNum+1))
   ((_testingTapTestNum=_testingTapTestNum+1))
   _testingDumpTempLog
   if (( ${_g_tap_format_enabled} )); then
      echo "not ok ${_testingTapTestNum} ${_testingTestFunction}_${_testingTestNum}"
   fi
   _testingSTDERR "[ X ]  ${_testingTestFunction}_${_testingTestNum}: ${_g_test_failure_message:-"test failed"}"
   _testingAssertionText=
   _g_test_failure_message=
   _saveTest
   _testingResetTempLog
}

function assert {
   # Tests ```stdin``` against the defined options.
   # >>> assert [!] [-lines,-l X|-f|-d|-n|-z|X|"str"] ["test_failure_message"]
   # !: Not operator.
   # -lines: Input should match X number of lines.
   # -f: Input is existing file.
   # -d: Input is existing directory.
   # -n: Input exists.
   # -z: Input is null.
   # X: Input equals number.
   # str: Input equals string.
   ${arcRequireBoundVariables}
   typeset assertion inverse gt lt eq line_count stdin is_file is_dir is_not_null is_null
   inverse=
   gt=
   lt=
   eq=
   line_count=0
   is_file=0
   is_dir=0
   is_not_null=0
   is_null=0
   while (( $# > 0)); do
      case "${1}" in
         "!") inverse="! "            ;;
         "-lines"|"-l") line_count=1  ;;
         "-f") is_file=1              ;;
         "-d") is_dir=1               ;;
         "-n") is_not_null=1          ;;
         "-z") is_null=1              ;;
         *) break ;;
      esac
      shift
   done
   assertion="${1:-}"
   if [[ -n "${2:-}" ]]; then
      _g_test_failure_message="${2}"
   fi
   if (( "${is_file}" )); then
      read stdin 
      if [[ -n "${inverse}" ]]; then
         _assertIsNotFile "${stdin}" && ${returnTrue}
       else
         _assertIsFile "${stdin}" && ${returnTrue}
      fi 
      ${returnFalse} 
   fi
   if (( "${is_dir}" )); then
      read stdin 
      if [[ -n "${inverse}" ]]; then
         _assertIsNotDir "${stdin}" && ${returnTrue}
       else
         _assertIsDir "${stdin}" && ${returnTrue}
      fi 
      ${returnFalse} 
   fi
   if (( "${is_not_null}" )); then
      read stdin 
      if [[ -n "${inverse}" ]]; then
         _assertIsNull "${stdin}" && ${returnTrue}
       else
         _assertIsNotNull "${stdin}" && ${returnTrue}
      fi 
      ${returnFalse} 
   fi
   if (( "${is_null}" )); then
      read stdin 
      if [[ -n "${inverse}" ]]; then
         _assertIsNotNull "${stdin}" && ${returnTrue}
       else
         _assertIsNull "${stdin}" && ${returnTrue}
      fi 
      ${returnFalse} 
   fi
   while (( 1 )); do
      case "${assertion:0:1}" in 
         # The space after ! is intentional.
         "!") inverse="! "  ;; 
         ">") gt=">"        ;;
         "<") lt="<"        ;;
         "=") eq="=="       ;;
         *) break           ;;
      esac
      assertion="${assertion:1}"
   done
   [[ -z "${gt:-}${lt:-}${eq:-}" ]] && eq="=="
   [[ -n "${gt:-}${lt:-}" && -n "${eq:-}" ]] && eq="=" 
   if (( ${line_count} )); then
      stdin=$(cat | tee -a "${_g_temp_log}" | wc -l | tr -d ' ')
   else
      stdin="$(cat | tee -a "${_g_temp_log}")"
   fi
   if num_is_num "${stdin}"; then
      # 'bc' does not work easily for Solaris 10, so sticking with nawk or awk here.
      if (( ${inverse} $(eval "${arcAwkProg} 'BEGIN {print ("$stdin" ${gt}${lt}${eq} "$assertion")}'") )); then
         (( ! ${_g_testing_self} )) && pass_test 
         ${returnTrue}
      else
         (( ! ${_g_testing_self} )) && fail_test 
         _testingSTDERR "[ * ]  '${inverse}(( ${stdin} ${gt}${lt}${eq} ${assertion} ))' is not true"
         ${returnFalse} 
      fi
   else 
      if eval "${inverse} [[ \"${stdin}\" == \"${assertion}\" ]]"; then
         (( ! ${_g_testing_self} )) && pass_test 
         ${returnTrue}
      else
         (( ! ${_g_testing_self} )) && fail_test 
         _testingSTDERR "[ * ]  '${inverse}[[ \"${stdin}\" == \"${assertion}\" ]]' is not true"
         ${returnFalse} 
      fi
   fi
}


function assert_true {
   # Assert that ```assertion``` is true.
   # >>> assert_true assertion ["test_failure_message"]
   ${arcRequireBoundVariables}
   typeset x
   x="${1:-}"
   if [[ -n "${2:-}" ]]; then
      _g_test_failure_message="${2}"
   fi
   x="${1}"
   if ! eval "${x}" 1> "${_g_temp_log}" 2> "${_g_temp_log}"; then
      _testingSTDERR "[ * ]  '${x:-}' is not true"
      (( ! ${_g_testing_self} )) && fail_test
      ${returnFalse} 
   else
      (( ! ${_g_testing_self} )) && pass_test
      ${returnTrue} 
   fi
}


function assert_false {
   # Assert that ```assertion``` is false.
   # >>> assert_false assertion ["test_failure_message"]
   ${arcRequireBoundVariables}
   typeset x
   if [[ -n "${2:-}" ]]; then
      _g_test_failure_message="${2}"
   fi
   x="${1}"
   if eval "${x}" 1> "${_g_temp_log}" 2> "${_g_temp_log}"; then
      _testingSTDERR "[ * ]  '${x:-}' is true"
      (( ! ${_g_testing_self} )) && fail_test
      ${returnFalse} 
   else
      (( ! ${_g_testing_self} )) && pass_test
      ${returnTrue} 
   fi
}


function assert_sleep {
   # Sleep for ```X``` seconds.
   # >>> assert_sleep X
   ${arcRequireBoundVariables}
   _testingSTDOUT "# Sleeping for ${1} seconds..."
   sleep ${1}
   ${returnTrue} 
}


function assert_banner {
   # Injects a message during testing. For example of you need to warn about some expected error or something.
   # >>> assert_banner "str"
   _testingSTDOUT "------------------------------------------------------------------------------"
   _testingSTDOUT "${1}"
   _testingSTDOUT "------------------------------------------------------------------------------"
}


function _assertIsFile {
   # Return true if ```actual``` is a file.
   # >>> _assertIsFile "actual"
   ${arcRequireBoundVariables}
   typeset actual
   actual="${1}"
   if [[ -f "${actual}" ]]; then
      (( ! ${_g_testing_self} )) && pass_test 
      ${returnTrue}
   else
      (( ! ${_g_testing_self} )) && fail_test 
      _testingSTDERR "[ * ]  '${actual}' is not a file or does not exist"
      ${returnFalse} 
   fi
}


function _assertIsNotFile {
   # Return true if ```actual``` is not a file.
   # >>> _assertIsNotFile "actual"
   ${arcRequireBoundVariables}
   typeset actual
   actual="${1}"
   if [[ ! -f "${actual}" ]]; then
      (( ! ${_g_testing_self} )) && pass_test 
      ${returnTrue}
   else
      (( ! ${_g_testing_self} )) && fail_test 
      _testingSTDERR "[ * ]  '${actual}' is a file and exists"
      ${returnFalse} 
   fi
}


function _assertIsDir {
   # Return true if ```actual``` is a directory.
   # >>> _assertIsDir "directory"
   ${arcRequireBoundVariables}
   typeset actual
   actual="${1}"
   if [[ -d "${actual}" ]]; then
      (( ! ${_g_testing_self} )) && pass_test 
      ${returnTrue}
   else
      (( ! ${_g_testing_self} )) && fail_test 
      _testingSTDERR "[ * ]  '${actual}' is not a directory or does not exist"
      ${returnFalse} 
   fi
}


function _assertIsNotDir {
   # Return true if ```actual``` is not a directory.
   # >>> _assertIsNotDir "actual"
   ${arcRequireBoundVariables}
   typeset actual
   actual="${1}"
   if [[ ! -d "${actual}" ]]; then
      (( ! ${_g_testing_self} )) && pass_test 
      ${returnTrue}
   else
      (( ! ${_g_testing_self} )) && fail_test 
      _testingSTDERR "[ * ]  '${actual}' is a directory"
      ${returnFalse} 
   fi
}


function _assertIsNotNull {
   # Return true if ```actual``` is not null.
   # >>> _assertIsNotNull "actual"
   ${arcRequireBoundVariables}
   typeset actual
   actual="${1:-}"
   if [[ -n "${actual:-}" ]]; then
      (( ! ${_g_testing_self} )) && pass_test 
      ${returnTrue}
   else
      (( ! ${_g_testing_self} )) && fail_test 
      _testingSTDERR "[ * ]  Actual value is null"
      ${returnFalse} 
   fi
}


function _assertIsNull {
   # Return true if ```actual``` is null.
   # >>> _assertIsNull "actual"
   ${arcRequireBoundVariables}
   typeset actual
   actual="${1:-}"
   if [[ -z "${actual:-}" ]]; then
      (( ! ${_g_testing_self} )) && pass_test 
      ${returnTrue}
   else
      (( ! ${_g_testing_self} )) && fail_test 
      _testingSTDERR "[ * ]  Actual value '${actual}' is not null"
      ${returnFalse} 
   fi
}


function _testingResetTempLog {
   # Truncate the temporary logging file.
   # >>> _testingResetTempLog
   cp /dev/null "${_g_temp_log}"
}

function _testingLogToTempLog {
   # Log an entry to the temp log.
   # >>> _testingLogToTempLog "string"
   if (( $# > 0 )); then
      echo "$*" >> "${_g_temp_log}"
   else
      cat >> "${_g_temp_log}"
   fi
}

function _testingDumpTempLog {
   # Dump the contents of the temp log to standard out. Up to 100 lines max.
   # >>> _testingDumpTempLog
   stderr_banner "Test Log"
   [[ -f "${_g_temp_log}" ]] && tail -1000 "${_g_temp_log}" | _testingSTDERR
}

function assert_match {
   # Asserts that at least one line from ```stdin``` matches ```regex```.
   # >>> assert_match "regex" ["test_failure_message"]
   ${arcRequireBoundVariables}
   typeset regex
   regex="${1}"
   if [[ -n "${2:-}" ]]; then
      _g_test_failure_message="${2}"
   fi
   if cat | tee -a "${_g_temp_log}" | egrep "${regex}" 1> /dev/null; then
      (( ! ${_g_testing_self} )) && pass_test 
      ${returnTrue} 
   else
      _testingSTDERR "[ * ]  assert_match: regex='${regex}'"
      (( ! ${_g_testing_self} )) &&  fail_test
      ${returnFalse} 
   fi
}


function assert_nomatch {
   # Asserts that none of the lines read from ```stdin``` match ```regex```.
   # >>> assert_nomatch "regex" ["test_failure_message"]
   ${arcRequireBoundVariables}
   typeset regex
   regex="${1}"
   if [[ -n "${2:-}" ]]; then
      _g_test_failure_message="${2}"
   fi
   if cat | tee -a "${_g_temp_log}" | grep "${regex}" 1> /dev/null; then
      _testingSTDERR "[ * ]  assert_nomatch: regex='${regex}'"
      (( ! ${_g_testing_self} )) && fail_test
      ${returnFalse} 
   else
      (( ! ${_g_testing_self} )) && pass_test 
      ${returnTrue} 
   fi
}


function _testingSetTestNum {
   # Sets the current test number within a test function.
   # >>> _testingSetTestNum number
   eval "$(_loadTest)"
   _testingTestNum="${1}"
   _saveTest
}

function _testingSTDOUT {
   # Write to standard out.
   # >>> _testingSTDOUT "string"
   if (( $# )); then
      echo "$*" 
   else
      cat 
   fi
}

function _testingSTDERR {
   # Write to standard error.
   # >>> _testingSTDERR "string"
   (( ${_g_tap_format_enabled} )) && ${returnTrue} 
   if (( $# )); then
      echo "$*" 3>&1 1>&2 2>&3
   else
      cat 3>&1 1>&2 2>&3
   fi
}

function _testingReturnTAPTestCount {
   # Return the TAP "plan".
   # >>> _testingReturnTAPTestCount "file"
   ${arcRequireBoundVariables}
   typeset file x
   file="${1}"
   x=$(_testingReturnTotalTestCount "${file}")
   echo "1..${x}"
}

function _testingStartTestRun {
   # Initializes the test run for a file.
   # >>> _testingStartTestRun "file"
   ${arcRequireBoundVariables}
   _testingTargetFile="${1}"
   eval "$(_loadTest)"
   _testingDebugStart

   _testingBeginTime=$(dt_epoch)
   _testingEndTime=
   if (( ${_g_tap_format_enabled} )); then
      _testingReturnTAPTestCount "${_testingTargetFile}"
   fi
   _testingSTDOUT "# -----------------------------------------------------------------------------"
   _testingSTDOUT "# Test File              : ${_testingTargetFile}"
   _testingSTDOUT "# Last Result            : ${_testingFinalResult}"
   _testingSTDOUT "# Last Time              : ${_testingElapsedSecs} seconds"
   _testingSTDOUT "# Shell Path             : ${_testingShellPath}"
   _testingSTDOUT "# -----------------------------------------------------------------------------"

   _testingPassCount=0
   _testingFailCount=0
   _testingTestNum=0
   _testingElapsedSecs=0
   _testingFinalResult=
   _testingTestFunction=
   _testingTapTestNum=0

   _saveTest
}

function _loadTest {
   # Returns the string to source in test state.
   # >>> eval "$(_loadTest)"
   ${arcRequireBoundVariables}
   if [[ -n "${1:-}" ]]; then
      _testingTargetFile="${1}"
   else
      _testingTargetFile="${_testingTargetFile}"
   fi
   [[ -z "${_testingTargetFile:-}" ]] && _testingThrowError "_loadTest: _testingTargetFile not defined!"
   _testingTargetDataFile="${_testingDir}/data/$(str_to_key_str "${_testingTargetFile}").dat"
   [[ ! -f "${_testingTargetDataFile}" ]] && _saveTest
   echo ". ${_testingTargetDataFile}"
}

function _saveTest {
   # Save the test state.
   # >>> _saveTest 
   ${arcRequireBoundVariables}
   [[ -z "${_testingTargetFile:-}" ]] && _testingThrowError "_saveTest: _testingTargetFile not defined!"
   _testingTargetDataFile="${_testingDir}/data/$(str_to_key_str "${_testingTargetFile}").dat"
   (
   cat <<EOF
_testingTargetFile="${_testingTargetFile}"
_testingAssertionText="${_testingAssertionText:-}"
_testingPassCount=${_testingPassCount:-0}
_testingFailCount=${_testingFailCount:-0}
_testingBeginTime=${_testingBeginTime:-0}
_testingEndTime=${_testingEndTime:-0}
_testingElapsedSecs=${_testingElapsedSecs:-0}
_testingFinalResult="${_testingFinalResult:-}"
_testingTestNum=${_testingTestNum:-0}
_testingTapTestNum=${_testingTapTestNum:-0}
EOF
   ) > "${_testingTargetDataFile}"
}

function _testingReturnFunctionCount {
   # Return the number of test functions in a file.
   # >>> _testingReturnFunctionCount "file"
   ${arcRequireBoundVariables}
   typeset file 
   file="${1}"
   _testingReturnListOfTestFunctions "${file}" | wc -l | tr -d ' '
}

function _testingReturnTotalTestCount {
   # Return the total number of individual tests from all related test files.
   # >>> _testingReturnTotalTestCount "file"
   ${arcRequireBoundVariables}
   typeset file
   file="${1}"
   (
   while read f; do
      _testingReturnTestCount "${f}"
   done < <(_testingReturnTestFiles "${file}")
   ) | num_sum -stdin -d 0
}

function _testingReturnTestCount {
   # Return the total number of tests in a file.
   # >>> _testingReturnTestCount "file"
   ${arcRequireBoundVariables}
   typeset file
   file="${1}"
   (
   str_remove_comments "${file}" | grep -n "pass_test" | egrep -v "fail_test" 
   str_remove_comments "${file}" | egrep "\|.*assert |assert_match|assert_nomatch"
   str_remove_comments "${file}" | grep "pass_test" | grep "fail_test"
   ) | wc -l | tr -d ' '
}

function _testingReturnListOfTestFunctions {
   # Returns the list of test functions from a file.
   # >>> _testingReturnListOfTestFunctions "file"
   ${arcRequireBoundVariables}
   typeset file 
   file="${1}"
   boot_list_functions "${file}" | grep "^test_" | \
      egrep -v "^test_file_setup|test_file_teardown|test_function_setup|test_function_teardown"
 }

function _testingHasFileSetup {
   # Return true if the test_file_setup function exists.
   # >>> _testingHasFileSetup "file"
   if grep "^function test_file_setup " "${1}" 1>/dev/null; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _testingHasFunctionSetup {
   # Return true if the test_function_setup function exists.
   # >>> _testingHasFunctionSetup "file"
   if grep "^function test_function_setup " "${1}" 1>/dev/null; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _testingHasFileTeardown {
   # Return true if the test_file_teardown function exists.
   # >>> _testingHasFileTeardown "file"
   if grep "^function test_file_teardown " "${1}" 1>/dev/null; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _testingHasFunctionTeardown {
   # Return true if the test_function_teardown function exists.
   # >>> _testingHasFunctionTeardown "file"
   if grep "^function test_function_teardown " "${1}" 1>/dev/null; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _testingReturnTestFiles {
   # Return the list of files which could contain tests.
   # >>> _testingReturnTestFiles "file_path"
   # file_path: Full path to primary test file.
   ${arcRequireBoundVariables}
   typeset file_path baseName rootName dirName testDir f
   file_path="${1}"
   # Ugly hack.
   if (( ${_g_lint_test} )); then
      _testingReturnLintFiles "${file_path}"
   else
      dirName=$(dirname "${file_path}")
      testDir="${dirName}/../test"
      baseName="$(basename "${file_path}")"
      rootName="$(file_get_file_root_name "${file_path}")"
      # Only return one of these files, both should never exist.
      if ! _testingEchoFileIfHasTests "${testDir}/${rootName}.test"; then
         _testingEchoFileIfHasTests "${testDir}/${baseName}"
      fi
      _testingEchoFileIfHasTests "${dirName}/${rootName}.test"
      _testingEchoFileIfHasTests "${file_path}"
   fi
}

function _testingEchoFileIfHasTests {
   #
   # >>> _testingEchoFileIfHasTests "file_path"
   if [[ -f "${1}" ]]; then
      if (( $(_testingReturnTestCount "${1}") > 0 )); then
         echo "${1}"
         ${returnTrue} 
      fi
   fi
   ${returnFalse} 
}

function _testingReturnLintFiles {
   # Return the list of files available lint files.
   # >>> _testingReturnLintFiles "file"
   ${arcRequireBoundVariables}
   typeset _testingTargetFile dirName testDir
   _testingTargetFile="${1}"
   dirName="$(dirname "${_testingTargetFile}")"
   find "${dirName}" -type f -name "*.lint"
   testDir="${dirName}/../test"
   [[ -d "${testDir}" ]] && find "${testDir}" -type f -name "*.lint"
}

function _testingEndTestRun {
   # Ends test run, reports results, and performs clean-up.
   # >>> _testingEndTestRun
   ${arcRequireBoundVariables}
   _testingCalcTestTiming
   _testingDebugStop
   if (( ${_testingFailCount} == 0 )); then
      _testingPassed
   else
      _testingFailed
   fi
}

function _testingFailed {
   # Actions to take when a file has one or more failures.
   # >>> _testingFailed
   ${arcRequireBoundVariables}
   typeset x 
   eval "$(_loadTest)"
   x="passed=${_testingPassCount}, failed=${_testingFailCount}"
   _testingFinalResult="Failed"
   _testingSTDERR "[ X ]  ${_testingTargetFile}: passed=${_testingPassCount}, failed=${_testingFailCount}"
   sanelog "FAIL" "${_testingTargetFile}" "${x}" >> "${_g_test_log}"
   _saveTest
}

function _testingPassed {
   # Actions to take when all tests pass.
   # >>> _testingPassed
   ${arcRequireBoundVariables}
   typeset x 
   eval "$(_loadTest)"
   x="passed=${_testingPassCount}, failed=${_testingFailCount}"
   _testingFinalResult="Passed"
   _testingSTDERR "[ p ]  ${_testingTargetFile}: passed=${_testingPassCount}, failed=${_testingFailCount}"
   sanelog "PASS" "${_testingTargetFile}" "${x}" >> "${_g_test_log}"
   _saveTest
}

function _testingCalcTestTiming {
   # Update a couple test timings and saves the record.
   # >>> _testingCalcTestTiming
   ${arcRequireBoundVariables}
   eval "$(_loadTest)"
   _testingEndTime=$(dt_epoch)
   ((_testingElapsedSecs=_testingEndTime-_testingBeginTime))
   _saveTest
}

function _testingThrowError {
   # Catch all error handler. Returns a formatted message to ```stderr```.
   # >>> _testingThrowError "error_message"
   throw_error "unittest.sh" "${1}"
}

typeset test_file test_shell

test_shell="$(which bash)"
if [[ -z "${test_shell:-}" ]]; then
   test_shell="$(which ksh)"
fi
if [[ -z "${test_shell:-}" ]]; then
   test_shell="$(which pdksh)"
fi
while (( $# > 0)); do
   case "${1}" in
      "-f") shift; test_file="${1}" ;;
      "-s") shift; test_shell="${1}" ;;
      *) break ;;
   esac
   shift
done

if [[ -n "${test_file:-}" ]]; then
   if [[ -f "${test_file}" ]]; then
      #gDebugLevel=2
      #gDebugOutput=2
      debug2 "unittest.sh: $*"
      typeset regex 
      regex="${2:-".*"}"
      unittest_test -shell "${test_shell}" "${test_file}" "${regex}"
      unittest_cleanup
   else
      _testingThrowError "Test file not found: ${test_file}: unittest.sh"
   fi
fi

