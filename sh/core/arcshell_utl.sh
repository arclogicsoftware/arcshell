

# module_name="Utilities"
# module_about="Misc. utilities."
# module_version=1
# module_image="magnet.png"
# copyright_notice="Copyright 2019 Arclogic Software"

_g_utlTestFile="${arcTmpDir}/utl$$.test"
_g_utlZipLastFilePath=

function __readmeUtilities {
   cat <<EOF
> Always code as if the guy who ends up maintaining your code will be a violent psychopath who knows where you live. -- Rick Osborne

# Utilities

**Misc. utilities.**

There are a number of general utilities here which do useful things and don't have a better place to go.

EOF
}

function test_file_setup {
   touch "${_g_utlTestFile}"
   echo "${_g_utlTestFile}" | assert -f
}

function test_function_setup {
   :
} 

function utl_return_matching_loaded_functions {
   # Return the list of matching function names from the current environment.
   # >>> utl_return_matching_loaded_functions ["regex"]
   # regex: Functions matching the regular expression are returned.
   ${arcRequireBoundVariables}
   typeset regex
   regex="${1:-".*"}"
   if boot_is_valid_bash; then
      declare -F | grep "^${regex}" | egrep -v "_grub" | cut -d" " -f3 | sort 
   else
      # Assumes ksh.
      typeset +f | grep "${regex}" | egrep -v "_grub" | sort 
   fi
}

function test_utl_return_matching_loaded_functions {
   :
}

function utl_confirm {
   # Return true if use response with a "truthy" value.
   # utl_confirm
   # __utl_confirm_skip: If this variable is set to 1 confirmations are skipped.
   ${arcRequireBoundVariables}
   typeset x 
   (( ${__utl_confirm_skip:-0} )) && ${returnTrue} 
   printf "Please confirm (y/n): " 
   read x 
   ! is_tty_device  &&  ${returnTrue} 
   if is_truthy "${x:-0}"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function utl_format_tags {
   # Formats the list of tags per standard ArcShell rules for tags.
   # >>> utl_format_tags "tags"
   # tags: A list of tags.
   utl_format_single_item_list "$*" | str_to_lower_case -stdin
}

function test_utl_format_tags {
   utl_format_tags "t,  k,a d   ,f" | assert "t,k,a,d,f" 
   utl_format_tags "g   ,a f t, #hello" | assert "g,a,f,t,#hello"
   utl_format_tags "Hi! HOWDY!" | assert "hi!,howdy!"
   utl_format_tags "#g #h #j #3 #4" | assert "#g,#h,#j,#3,#4"
}

function utl_format_single_item_list {
   # Turns a list with commas or spaces into a single list with commas.
   # >>> utl_format_single_item_list "tags"
   # tags: A list of tags.
   echo "$*" | tr ' ' ',' | str_split_line -stdin "," | \
      utl_remove_blank_lines -stdin | str_to_csv ","
}

function test_utl_format_single_item_list {
   utl_format_single_item_list "t,  k,a d   ,f" | assert "t,k,a,d,f" 
   utl_format_single_item_list "g   ,a f t, #hello" | assert "g,a,f,t,#hello"
   utl_format_single_item_list "Hi! HOWDY!" | assert "Hi!,HOWDY!"
   utl_format_single_item_list "#g #h #j #3 #4" | assert "#g,#h,#j,#3,#4"
}

function utl_get_function_body {
   # Returns the function body. Removes first 3 characters which should be spaces.
   # >>> utl_get_function_body "file_path" "func_name"
   # file_path: Path to file.
   # func_name: Name of function.
   ${arcRequireBoundVariables}
   typeset file_path func_name start lines x
   file_path="${1}"
   func_name="${2}"
   start=$(grep -n "^function ${func_name} " "${file_path}" | cut -d":" -f1)
   ((start=start+1))
   lines=$(wc -l "${file_path}" | cut -d" " -f1)
   if [[ -n "${start}" && -n "${lines}" ]] && (( ${start} > 1 )); then   
      echo ""
      while IFS= read -r x; do
         if [[ "${x:0:1}" == "}" ]]; then
            break
         fi
         echo "${x}"
      done < <(sed -n "${start},${lines}p" "${file_path}")
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function utl_get_function_def {
   # Returns a function definition from a file.
   # >>> utl_get_function_def "file_path" "func_name"
   # file_path: Path to file.
   # func_name: Name of function.
   ${arcRequireBoundVariables}
   typeset file_path func_name start lines x
   file_path="${1}"
   func_name="${2}"
   start=$(grep -n "^function ${func_name} " "${file_path}" | cut -d":" -f1)
   lines=$(wc -l "${file_path}" | cut -d" " -f1)
   echo ""
   if [[ -n "${start}" && -n "${lines}" ]]; then   
      while IFS= read -r x; do
         echo "${x}"
         if [[ "${x:0:1}" == "}" ]]; then
            break
         fi
      done < <(sed -n "${start},${lines}p" "${file_path}")
   fi
}

function utl_get_function_doc {
   # Returns the function documentation from a file.
   # >>> utl_get_function_doc "file_path" "func_name"
   # file_path: Path to file.
   # func_name: Name of function.
   ${arcRequireBoundVariables}
   typeset file_path func_name line_no started line 
   file_path="${1}"
   func_name="${2}"
   line_no=0 
   started=0
   while read line; do
      ((line_no=line_no+1))
      if (( ${line_no} == 2 )) && [[ "${line:0:1}" == "#" ]]; then
         started=1
      fi
      if [[ "${line:0:1}" == "#" ]] && (( ${started} )); then
         echo "${line}"
      fi
      if [[ "${line:0:1}" != "#" ]] && (( ${started} )); then
         started=0
      fi
   done < <(utl_get_function_def "${file_path}" "${func_name}" | utl_remove_blank_lines -stdin)
}

function utl_inspect_model_definition {
   # 
   # >>> utl_inspect_model_definition "model_definition" "actual_definition"
   ${arcRequireBoundVariables}
   typeset model_definition actual_definition var 
   model_definition="${1}"
   actual_definition="${2}"
   while read var; do
      if (( $(echo "${model_definition}" | grep "^${var}=" | wc -l) == 0 )); then
         echo "Make sure '${var}' isn't a typo."
      fi
   done < <(echo "${actual_definition:-}" | _utlReturnPossibleVars)
}

function test_utl_inspect_model_definition {
   m="
foo=
not=
"
   d="
foo='bar'
zim='zab'"

   utl_inspect_model_definition "${m}" "${d}" | assert_match "zim.*typo" "Inspection should provide warning for zim."

d="
not=1
if (( 1 == 2 )); then
   zim=0
fi
"
   utl_inspect_model_definition "${m}" "${d}" | assert_match "zim.*typo" "Inspection should provide warning for zim."

}

function _utlReturnPossibleVars {
   # Return things which look like variables from ```stdin```.
   # >>> _utlReturnPossibleVars 
   cat | str_trim_line -stdin | egrep "^[A-Z|a-z|_]*=" | awk -F"=" '{print $1}'
}

function _sshInspectNodeDefinition {
   # Return warnings for variables which are not found in the model.
   # >>> _sshInspectNodeDefinition "node" "definition""
   ${arcRequireBoundVariables}
   typeset node_name node_definition var x  
   node_name="${1}"
   node_definition="${2:-}"
   debug0 "Inspecting definition for '${node_name}'..."
   while read var; do
      if (( $(_sshNodeModel | grep "^${var}=" | wc -l) == 0 )); then
         echo "Make sure '${var}' isn't a typo."
      fi
   done < <(echo "${node_definition:-}" | _sshReturnPossibleVars)
}

function utl_add_dirs_to_unix_path {
   # Adds a bunch of values to the current path string if they don't exist and returns the new string.
   # >>> utl_add_dirs_to_unix_path "path" "path" "path"
   # path: One or more values you would like to add to the path.
   ${arcRequireBoundVariables}
   tmpFile="$(mktempf)"
   # The awk command here enables us to get a unique list and also maintain the order or that list..
   echo "${PATH:-}" | str_split_line ":" | str_uniq -stdin > "${tmpFile}"
   while (( $# > 0 )); do
      if (( $(grep "${1}" "${tmpFile}" | wc -l) == 0 )); then
         echo "${1}" >> "${tmpFile}"
      fi
      shift 
   done
   cat "${tmpFile}" | str_to_csv ":"
   rm "${tmpFile}"
}

function test_utl_add_dirs_to_unix_path {
   :
}

function utl_zip_file {
   # Zip a file using gzip or compress depending on which program is available.
   # >>> utl_zip_file "file"
   ${arcRequireBoundVariables}
   debug2 "utl_zip_file: $*"
   typeset filePath fileEnding zipProgram
   _g_utlZipLastFilePath=
   filePath="${1}"
   file_raise_file_not_found "${filePath}" && ${returnFalse}
   if boot_is_program_found "gzip"; then
      fileEnding=".gz"
      zipProgram="gzip"
   elif boot_is_program_found "compress"; then
      fileEnding=".Z"
      zipProgram="compress"
   else
      _utlThrowError "'gzip' and 'compress' not found: $*: utl_zip_file"
      ${returnFalse}
   fi
   if [[ -f "${filePath}${fileEnding}" ]]; then
      rm "${filePath}${fileEnding}"
   fi
   "${zipProgram}" "${filePath}"
   if [[ -f "${filePath}${fileEnding}" ]]; then
      _g_utlZipLastFilePath="${filePath}${fileEnding}"
      ${returnTrue}
   else
      _utlThrowError "Error zipping file: ${filePath}${fileEnding}: utl_zip_file"
      _g_utlZipLastFilePath="${filePath}"
      ${returnFalse}
   fi
}

function test_utl_zip_file {
   :
}

function utl_zip_get_last_file_path {
   # Return the full path to the last file compressed or zipped.
   # utl_zip_get_last_file_path
   echo "${_g_utlZipLastFilePath:-}"
}

function test_utl_zip_get_last_file_path {
   :
}

function utl_raise_empty_var {
   # Throw error and return true if $1 is not set.
   # >>> utl_raise_empty_var "error_message" "${check_variable}"
   # error_message: The message to display if the second argument is empty/null/undefined.
   # check_variable: The variable itself is passed in here.
   ${arcRequireBoundVariables}
   typeset error_message check_variable
   error_message="${1}"
   check_variable="${2:-}"
   if [[ -z "${check_variable:-}" ]]; then
      _utlThrowError "${error_message}: utl_raise_empty_var"
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_utl_raise_empty_var {
   :
}

function utl_does_file_end_with_newline {
   # Return true if the file ends with a new line character.
   # >>> utl_does_file_end_with_newline "file"
   ${arcRequireBoundVariables}
   typeset file_name x
   file_name="${1}"
   if [[ -f "${file_name}" ]]; then
      x=$(wc -l < <(tail -1 "${file_name}"))
      if (( "${x}" )); then
         ${returnTrue}
      else
         ${returnFalse}
      fi
   else
      _utlThrowError "File not found: $*: utl_does_file_end_with_newline"
   fi
}

function utl_add_missing_newline_to_end_of_file {
   # Adds \n to the end of a file if it is missing. 
   # >>> utl_add_missing_newline_to_end_of_file "file"
   ${arcRequireBoundVariables}
   typeset file_name
   file_name="${1}"
   if [[ -f "${file_name}" ]]; then
      ! utl_does_file_end_with_newline "${file_name}" && echo "" >> "${file_name}"
   else
      _utlThrowError "File not found: $*: utl_add_missing_newline_to_end_of_file"
   fi
}

function utl_raise_invalid_option {
   # Checks for some common issues when processing command line args.
   # >>> utl_raise_invalid_option "function" "(( \$# <= 9 ))" ["\$*"]
   # function: A string to identify the source of the call, usually the function name.
   # (( \$# <= 9 )): How many args should there be? If false throw error.
   # \$*: Argument list. If next arg starts is -something throw an error.
   ${arcRequireBoundVariables}
   typeset function_name arg_list arg_assertion
   function_name="${1}"
   arg_assertion="${2}"
   arg_list="${3:-}"
   if [[ "${arg_list:0:1}" == "-" ]]; then
      _utlThrowError "Next argument in list appears to be invalid: $*: ${function_name}"
      ${returnTrue} 
   elif ! eval "${arg_assertion}"; then
      _utlThrowError "The number of remaining arguments appears to be incorrect: $*: ${function_name}"
      ${returnTrue} 
   else
      ${returnFalse}
   fi
}

function test_utl_raise_invalid_option {
   utl_raise_invalid_option "foo" "(( $# <= 0 ))" "bluff" && fail_test "Valid options should return false." || pass_test 
   utl_raise_invalid_option "foo" "(( 5 <= 0 ))" "bluff" 2> /dev/null && pass_test || fail_test "Invalid arg count should return true."
   utl_raise_invalid_option "foo" "(( 0 <= 0 ))" "-bluff" 2> /dev/null && pass_test || fail_test "Should have returned true if next remaining arg started with a -."
}

function utl_raise_invalid_arg_option {
   # Raise and error and return true if the provided arg begins with a dash.
   # >>> utl_raise_invalid_arg_option "errorText" "\$*" 
   # errorText: Error string to include in general error message.
   ${arcRequireBoundVariables}
   typeset argList errorText 
   errorText="${1}"
   argList="${2}"
   if [[ "${argList:0:1}" == "-" ]]; then
      _utlThrowError "Named arg not recognized: $*: ${errorText}"
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_utl_raise_invalid_arg_option {
   utl_raise_invalid_arg_option "test_function" "foo" | assert -l 0 
   ! utl_raise_invalid_arg_option "test_function" "foo" && pass_test || fail_test
   utl_raise_invalid_arg_option "test_function" "-foo" 2>&1 | assert_match "ERROR"
   utl_raise_invalid_arg_option "test_function" "-foo" 2> /dev/null && pass_test || fail_test
}

function utl_raise_invalid_arg_count {
   # Throw error and return true if expression passed into the function is not true.
   # >>> utl_raise_invalid_arg_count "errorText" "(( \$# == X ))" 
   # errorText: Error string to include in general error message.
   # (( \$# == X )): Test the number of args remaining. If this is not true an error is raised.
   ${arcRequireBoundVariables}
   typeset testExpression 
   errorText="${1}"
   testExpression="${2}"
   if eval "${2}"; then
      ${returnFalse}
   else
      _utlThrowError "Argument count is incorrect: $*: ${errorText:-}"
      ${returnTrue}
   fi
}

function test_utl_raise_invalid_arg_count {
   utl_raise_invalid_arg_count "test_function" "(( 1 == 1 ))" | assert -l 0 
   ! utl_raise_invalid_arg_count "test_function" "(( 1 == 1 ))" && pass_test || fail_test
   utl_raise_invalid_arg_count "test_function" "(( 2 == 1 ))" 2>&1 | assert_match "ERROR"
   utl_raise_invalid_arg_count "test_function" "(( 2 == 1 ))" 2> /dev/null && pass_test || fail_test
}

function utl_raise_dir_not_found {
   # Throw error and return true if the provided directory is not found or executable bit is not set.
   # >>> utl_raise_dir_not_found "directory"
   ${arcRequireBoundVariables}
   typeset dirPath 
   dirPath="${1}"
   if [[ -d "${dirPath}" && -x "${dirPath}" ]]; then
      ${returnFalse}
   else
      _utlThrowError "Directory not found or executable bit is not set: $*: utl_raise_dir_not_found"
      ${returnTrue}
   fi
}

function test_utl_raise_dir_not_found {
   ! utl_raise_dir_not_found "/tmp" && pass_test || fail_test 
   utl_raise_dir_not_found "/tmp_not" 2> /dev/null && pass_test || fail_test 
   rm -rf "/tmp/test$$" 2> /dev/null
   mkdir "/tmp/test$$"
   ! utl_raise_dir_not_found "/tmp/test$$" && pass_test || fail_test 
   chmod 600 "/tmp/test$$"
   utl_raise_dir_not_found "/tmp/test$$" 2>&1 | assert_match "ERROR" 
   chmod 700 "/tmp/test$$"
   rm -rf "/tmp/test$$"
}

function utl_set_version {
   # >>> utl_set_version "name" version
   # name: A simple string identifying the object to set the version for.
   # version: Must be a number.
   ${arcRequireBoundVariables}
   typeset objectName objectVersion storedVersion 
   objectName="${1}"
   objectVersion=${2}
   if num_is_num "${objectVersion}"; then
      storedVersion=$(utl_get_version "${objectName}")
      cache_save -group "objectVersions" "${objectName}" ${objectVersion}
      if (( ${storedVersion} != ${objectVersion} )); then
         debug1 "'${objectName}' set to version ${objectVersion}."
      fi
   else
      _utlThrowError "Version must be a number: $*: utl_set_version"
   fi
}

function utl_get_version {
   # Return the version number for an object. 0 is returned if the object is not found.
   # >>> utl_get_version "name"
   ${arcRequireBoundVariables}
   typeset objectName objectVersion v
   objectName="${1}"
   v=$(cache_get -default 0 -group "objectVersions" "${objectName}")
   echo ${v}
}

function utl_remove_trailing_blank_lines {
   # Remove trailing blank lines from a file or input stream.
   # >>> utl_remove_trailing_blank_lines ["file"]
   # file: Optional file name, otherwise expects input stream from standard input.
   #
   # **Example**
   # ```
   # $ (        
   # > cat <<EOF
   # > 
   # > A
   # > B
   # > 
   # > EOF
   # > ) | utl_remove_trailing_blank_lines
   #
   # A
   # B
   #
   # ```
   ${arcRequireBoundVariables}
   debug3 "utl_remove_trailing_blank_lines: $*"
   if [[ -n "${1:-}" && -f "${1:-}" ]]; then
      cat "${1}" | utl_remove_trailing_blank_lines
   else
      str_reverse_cat | str_remove_leading_blank_lines | str_reverse_cat
   fi
}

function test_utl_remove_trailing_blank_lines {
   (
   cat <<EOF

a
1

z
2

EOF
   ) > "${_g_utlTestFile}"
   #debug_start 3
   utl_remove_trailing_blank_lines "${_g_utlTestFile}" | tail -1 | assert 2
   #debug_dump
   #debug_start 3
   cat "${_g_utlTestFile}" | utl_remove_trailing_blank_lines | tail -1 | assert 2
   #debug_dump
   cat "${_g_utlTestFile}" | utl_remove_blank_lines -stdin | utl_remove_trailing_blank_lines | tail -1 | assert 2
}

function utl_first_unblank_line {
   # Return the first unblank line in a file or input stream.
   # >>> utl_first_unblank_line ["file"]
   # file: Optional file name, otherwise expects input stream from standard input.
   debug2 "utl_first_unblank_line: $*"
   ${arcRequireBoundVariables}
   if [[ -n "${1:-}" ]]; then
      cat "${1}"| utl_first_unblank_line
   else
      utl_remove_blank_lines -stdin | head -1
   fi
}

function test_utl_first_unblank_line {
   (
   cat <<EOF

LINE2
LINE3
EOF
   ) | utl_first_unblank_line | assert "LINE2"
}

function utl_remove_blank_lines {
   # Removes blank lines from a file or input stream.
   # >>> utl_remove_blank_lines [-stdin|"file_path"]
   # -stdin: Reads input from standard in.
   # file_path: Path to file.
   #
   # **Example**
   # ```bash
   # cat /tmp/example.txt | utl_remove_blank_lines -stdin
   # ```
   ${arcRequireBoundVariables}
   if [[ "${1:-}" == "-stdin" ]]; then
      egrep -v "^ *$|^$"
   else 
      echo "${1}" | utl_remove_blank_lines -stdin
   fi
}

function test_utl_remove_blank_lines {
   (
   cat <<EOF

FOO

FOO
EOF
   ) | utl_remove_blank_lines -stdin | wc -l | assert 2
}

function utl_found_in_path_def {
   # Return true if value is not defined as part of ${PATH}.
   # >>> utl_found_in_path_def "directory")
   ${arcRequireBoundVariables}
   typeset directoryPath
   directoryPath="${1}"
   if (( $(echo "${PATH}" | str_split_line ":" | grep "${directoryPath}" | wc -l) )); then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_utl_found_in_path_def {
   originalPath="${PATH}"
   PATH="${originalPath}:/tmp/foo:.:"
   ! utl_found_in_path_def "/tmp/zoo" && pass_test || fail_test
   utl_found_in_path_def "/tmp/foo" && pass_test || fail_test
   utl_found_in_path_def "." && pass_test || fail_test
   PATH="${originalPath}"
}

function is_not_defined {
   # Return true if provided variable is not defined.
   # >>> is_not_defined "variable" 
   # variable: Variable to check.
   #
   # **Example**
   # ```
   # $ foo=
   # $ is_not_defined "${foo}" && echo "OK" || echo "Not Defined"
   # OK
   # ```
   ${arcRequireBoundVariables}
   debug3 "is_not_defined: $*"
   if [[ -z "${1:-}" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_is_not_defined {
   X=
   is_not_defined "${X}" && pass_test || fail_test
   X=0
   ! is_not_defined "${X}" && pass_test || fail_test
}

function is_defined {
   # Return true if provided variable is defined.
   # >>> is_defined "X" 
   # X: Variable to check.
   #
   # **Example**
   # ```
   # $ foo=
   # $ is_defined "${foo}" && echo "OK" || echo "Not Defined"
   # Not Defined
   # ```
   ${arcRequireBoundVariables}
   if [[ -n "${1:-}" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_is_defined {
   X=0
   is_defined "${X}" && pass_test || fail_test
   X=
   ! is_defined "${X}" && pass_test || fail_test
}

function get_shell_type {
   # Determine if current shell is bash or ksh.
   # >>> get_shell_type
   ${arcRequireBoundVariables}
   [[ -n "${BASH:-}" ]] &&  echo "bash" ||  echo "ksh"
}

function test_get_shell_type {
   get_shell_type | egrep "ksh|bash" | assert -l 1
}

function is_linux {
   # Return true if current OS is Linux.
   # >>> is_linux
   ${arcRequireBoundVariables}
   if [[ $(uname -s | str_to_upper_case -stdin) == "LINUX" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_is_linux {
   if [[ "${arcOSType}" == "LINUX" ]]; then
      is_linux && pass_test || fail_test
   fi
}

function is_email_address {
   # Return true if provided string contains an @ and is therefore likely an email address.
   # >>> is_email_address "emailAddressStringToCheck"
   ${arcRequireBoundVariables}
   if (( $(str_instr "@" "${1}") > 0 )); then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_is_email_address {
   is_email_address "post.ethan@gmail.com" && pass_test || fail_test
   ! is_email_address "post.ethan" && pass_test || fail_test
}

function utl_to_stderr {
   # Write a text string to standard error.
   # >>> utl_to_stderr "textString"
   ${arcRequireBoundVariables}
   typeset textString
   textString="${1}"
   echo "${textString}" 3>&1 1>&2 2>&3
}

function test_utl_to_stderr {
   utility_write_stderr "foo" 2>&1 >/dev/null | assert -n
}

function _is_truthy {
   # Return true if parameter is truthy, (e.g., 'y', 1, 'yes', true).
   # >>> is_truthy "truthyValue"
   ${arcRequireBoundVariables}
   typeset x
   x="${1:-}"
   case "${x}" in 
      "y"|"Y"|1|"true"|"True"|"TRUE"|"yes"|"Yes"|"YES")
         ${returnTrue}
         ;;
      *)
         ${returnFalse}
         ;;
   esac
}

function is_truthy {
   # Return true if value is truthy.
   # Truthy values are true cron expressions, 1, y, yes, t, true. Upper or lower-case.
   # >>> is_truthy "truthyValue"|"cronExpression"
   ${arcRequireBoundVariables}
   [[ -z "${1:-}" ]] && ${returnFalse} 
   if (( $(echo "${1:-0}" | wc -w) == 1 )); then
      if _is_truthy "${1:-0}"; then
         ${returnTrue}
      else
         ${returnFalse}
      fi
   elif [[ -n "${1:-}" ]] && cron_is_true "${1:-}"; then 
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_is_truthy {
   typeset x
   for x in 'y' 1 'yes' 'Y' 'YES' 'Yes' 'TRUE' 'True' 'true' '* * * * *'; do
      is_truthy "${x}" && pass_test || fail_test
   done
   for x in 'n' 0 'no' 'N' 'NO' 'No' 'FALSE' 'False' 'false' '23 0 * * 6'; do
      ! is_truthy "${x}" && pass_test || fail_test
   done
   ! is_truthy && pass_test || fail_test
}

function mktempf {
   # Return path to a newly created temp file.
   # >>> mktempf ["string"]
   # string: A string which can be used to identify the source of the file.
   ${arcRequireBoundVariables}
   typeset x str tmpDir tmpFile
   x=${RANDOM:-0}
   if is_defined "${1:-}"; then
      str="${1}"
      tmpDir="${arcTmpDir}/tmp/$$/${str}"
      mkdir -p "${tmpDir}"
      tmpFile="${tmpDir}/${x}.tmp"
   else
      tmpDir="${arcTmpDir}/tmp"
      mkdir -p "${tmpDir}"
      tmpFile="${tmpDir}/${x}.tmp"
   fi
   while [[ -f "${tmpFile}" ]]; do
      ((x=x+1))
      tmpFile="${tmpDir}/${x}.tmp"
   done
   (umask 077 && touch "${tmpFile}")
   echo "${tmpFile}"
}

function test_mktempf {
   typeset x
   rmtempf 
   x="$(mktempf "foo")"
   touch "${x}"
   [[ -f "${x}" ]] && pass_test || fail_test 
   y="$(mktempf "foo")"
   touch "${y}"
   ! [[ "${x}" -ef "${y}" ]] && pass_test || fail_test 
   ls "${arcTmpDir}/tmp/$$/foo"* | assert -l 2
}

function rmtempf {
   # Deletes any temp files this session has created. If ```string``` is provided, deletes are limited to matching files.
   # >>> rmtempf "string"
   # string: A string to easily identify a group of tmp files.
   ${arcRequireBoundVariables}
   typeset str tmpDir tmpFile
   str="${1:-}"
   tmpDir="${arcTmpDir}/tmp/$$/${str}"
   if $(file_is_dir "${tmpDir}"); then
      rm -rf "${tmpDir}" 
   fi
}

function test_rmtempf {
   rmtempf 2>&1 | assert -z
   # Should not return an error when no files exist.
   rmtempf 2>&1 >/dev/null | assert -z
   echo "${arcTmpDir}/tmp/$$" | assert ! -d
   x=$(mktempf "unittest")
   echo "${arcTmpDir}/tmp/$$" | assert -d
   rmtempf
   echo "${arcTmpDir}/tmp/$$" | assert ! -d
}

function mktempd {
   # Returns the path to a new temporary directory.
   # >>> mktempd
   ${arcRequireBoundVariables}
   typeset tmpDir
   tmpDir="${arcTmpDir}/tmp/$$_${RANDOM:-0}_$(dt_epoch)"
   mkdir -p "${tmpDir}"
   echo "${tmpDir}"
}

function test_mktempd {
   T=$(mktempd) 
   [[ -d "${T}" ]] && pass_test || fail_test 
   rmtempd "${T}"
   [[ -d "${T}" ]] && fail_test || pass_test 
   X=$(mktempd) 
   Y=$(mktempd) 
   ! [[ "${X}" -ef "${Y}" ]] && pass_test || fail_test 
   rmtempd "${X}"
   rmtempd "${Y}"
}

function rmtempd {
   # A safe way to delete a directory created with mktempd.
   # >>> rmtempd "directory"
   ${arcRequireBoundVariables}
   typeset file directory
   directory="${1:-}"
   if [[ -d "${directory:-}" ]]; then
      file="$(basename ${directory})"
      if [[ -d "${arcTmpDir}/tmp/${file}" ]]; then
         rm -rf "${arcTmpDir}/tmp/${file}"
      fi
   else
      _utlThrowError "Directory not found: $*: rmtempd"
   fi
}

function test_rmtempd {
   typeset t 
   t="$(mktempd)"
   echo "${t}" | assert -d 
   rmtempd "${t}"
   echo "${t}" | assert ! -d 
   rmtempd 2>&1 >/dev/null | assert_match "ERROR"
}

function _utlThrowError {
   # Utility module error handler.
   # >>> _utlThrowError "errorText"
   throw_error "arcshell_utl.sh" "${1}"
}

function test_file_teardown {
   rm "${_g_utlTestFile}"* 2> /dev/null
   echo "${_g_utlTestFile}" | assert ! -f
}


