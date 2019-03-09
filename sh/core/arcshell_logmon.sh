
# module_name="Log Monitoring"
# module_about="Monitor log files. Trigger alerts, notifications, and log entries using flexible log file handlers."
# module_version=1
# module_image="view.png"
# copyright_notice="Copyright 2019 Arclogic Software"

_logmonDir="${arcTmpDir}/_arcshell_logmon"
mkdir -p "${_logmonDir}"

fooFile=
_g_logmonBufferFile="${_logmonDir}/$$.data"
_g_logmonMeta=

function __readmeLogmon {
   cat <<EOF
## Log Monitoring

This short code block shows how easy it is to monitor logs with 
ArcShell. New lines are read from the file using **logmon_read_log**
and piped to a handler called **var_log_messages**. Notifications and
other actions are configured within the handler.

\`\`\`bash
logmon_read_log -max 10 "/var/log/messages" | \\
   logmon_handle_log -stdin "var_log_messages"
\`\`\`

EOF
}

# ToDo: Enable named buffers instead of just numbered.

function test_file_setup {
   __setupLogmon
   fooFile="/tmp/logmon.foo"
   fooKey="$(str_to_key_str "${fooFile}")"
   logmon_forget_file "${fooFile}"
}

function __setupLogmon {
   # This special function is run during setup.
   objects_register_object_model "logmon" "_logmonRecord" 
   # ToDo: This could be abstracted away to use any check sum program available.
   if boot_raise_program_not_found "cksum"; then
      log_error -2 -logkey "logmon" "'cksum' not found. This program is required for some logmon actions."
   fi
}

# ToDo: Allow user to register a file without the copy. Useful for very large files.

function logmon_register_file {
   # Copies the contents of 'file_name' to the zero buffer. Used for testing. 
   # >>> logmon_register_file "file_name"
   ${arcRequireBoundVariables}
   debug3 "logmon_register_file: $*"
   logmon_reset
   cp "${1}" "${_g_logmonBufferFile}0"
}

function logmon_cat {
   # Returns the specified buffer to standard out.
   # >>> logmon_cat [-from,-f "X"]
   ${arcRequireBoundVariables}
   typeset from_buffer_id
   from_buffer_id="0"
   while (( $# > 0)); do
      case "${1}" in
         "-from"|"-f") shift; from_buffer_id="$(str_to_key_str "${1}")" ;;
         *) break ;;
      esac
      shift
   done
   file_raise_file_not_found "${_g_logmonBufferFile}${from_buffer_id}" && ${returnFalse} 
   cat "${_g_logmonBufferFile}${from_buffer_id}"
   ${returnTrue} 
}

function logmon_append {
   # Appends matching lines from one buffer to another.
   # >>> logmon_append [-ignore_case,-i] [-from,-f "X"] -to,-t "X" ["regex"]
   # -ignore_case:
   # -from: From buffer id.
   # -to: To buffer id.
   # regex: 
   ${arcRequireBoundVariables}
   debug3 "logmon_append: $*"
   typeset ignore_case from_buffer_id to_buffer_id regex
   ignore_case=0
   from_buffer_id="0"
   to_buffer_id=
   regex=".*"
   while (( $# > 0)); do
      case "${1}" in
         "-from"|"-f") shift; from_buffer_id="$(str_to_key_str "${1}")" ;;
         "-to"|"-t") shift; to_buffer_id="$(str_to_key_str "${1}")" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "logmon_append" "(( $# <= 1 ))" "$*" && ${returnFalse}
   utl_raise_empty_var "to_buffer_id not set. Try using the -to option." "${to_buffer_id:-}" && ${returnFalse} 
   (( $# == 1 )) && regex="${1}"
   file_raise_file_not_found "${_g_logmonBufferFile}${from_buffer_id}" && ${returnFalse} 
   _logmonGrep ${ignore_case} "${from_buffer_id}" "${regex}" >> "${_g_logmonBufferFile}${to_buffer_id}"
   ${returnTrue} 
}

function _logmonRecord {
   # Returns the default record which stores data about a monitored log file.
   # >>> _logmonRecord
   cat <<EOF
_logmonFileBytes=${_logmonFileBytes:-0}
_logmonSizePlusMinusEqual=${_logmonSizePlusMinusEqual:-"="}
_logmonHeaderHash=${_logmonHeaderHash:-0}
_logmonHeaderModifiedFlag=${_logmonHeaderModifiedFlag:-0}
_logmonFileMaxSizeInBytes=${_logmonFileMaxSizeInBytes:-0}
_logmonMaxReadBytes=${_logmonMaxReadBytes:-0}
_logmonFileUpdateTime=${_logmonFileUpdateTime:-0}
_logmonStartingByte=${_logmonStartingByte:-0}
EOF
}

function logmon_reset {
   # Removes all buffer files and resets a couple of global variables.
   # >>> logmon_reset
   find "${_logmonDir}" -type f -name "$(basename ${_g_logmonBufferFile})*" -exec rm {} \;
   _g_logmonMeta=
   _g_logmonBufferFile="${_logmonDir}/$$.data"
}

function logmon_read_log {
   # This function is used to intermittently check files for new lines and return only those lines.
   # >>> logmon_read_log [-new,-n] [-max,-m X] "filePath"
   # -new: If file is new existing lines are treated as new lines.
   # -max: Limit amount of data that can be returned to X megabytes. Defaults to 10.
   typeset is_new_file return_new_files max_read_bytes filePath fileKey
   debug3 "logmon_read_log: $*"
   filePath=
   fileKey=
   eval "$(objects_init_object "logmon")"
   return_new_files=0
   ((max_read_bytes=10*1024*1024))
   is_new_file=0
   while (( $# > 0)); do
      case ${1} in
         "-new"|"-n") return_new_files=1 ;;
         "-max"|"-m") shift; ((max_read_bytes=${1}*1024*1024)) ;;
         *) break                                              ;;
      esac
      shift
   done
   utl_raise_invalid_option "logmon_read_log" "(( $# == 1 ))" "$*" && ${returnFalse} 
   filePath="${1}"
   if ! file_is_full_path "${filePath}"; then
      filePath="$(pwd)/${filePath}"
   fi
   fileKey="$(str_to_key_str "${filePath}")"
   if [[ ! -f "${filePath}" ]]; then
      # Log file may have been deleted.
      logmon_forget_file "${filePath}"
      ${returnFalse}  
   fi
   _logmonIsNewFileKey "${fileKey}" && is_new_file=1
   if (( ${is_new_file} )); then
      _logmonMaxReadBytes=${max_read_bytes}
      objects_save_temporary_object "logmon" "${fileKey}"
   fi
   eval "$(objects_load_object "logmon" "${fileKey}")"
   # It is possible that max_read_bytes changes between calls for the same file.
   if (( ${max_read_bytes:-0} != ${_logmonMaxReadBytes:-0} )); then
      _logmonMaxReadBytes=${max_read_bytes:-0}
      objects_save_temporary_object "logmon" "${fileKey}"
   fi
   _logmonUpdateFile "${filePath}" "${fileKey}"
   if ! (( ${is_new_file} )) || (( ${is_new_file} && ${return_new_files} )); then
      [[ -s "${filePath}" ]] && _logmonProcessFile "${filePath}" "${fileKey}"
   fi
}

function test_logmon_read_log {
   typeset fooKey
   fooKey="$(str_to_key_str "${fooFile}")"
   cp /dev/null "${fooFile}"
   echo "foo" >> "${fooFile}"
   logmon_read_log "${fooFile}" | assert -l 0 "New file should not return data."
   logmon_forget_file "${fooFile}"
   logmon_read_log -new "${fooFile}" | assert -l 1 "New file should return data when -new option is used."
   logmon_read_log -new "${fooFile}" | assert -l 0 "File did not change, why was data returned?"
   echo "Let me not then die..." >> "${fooFile}"
   logmon_read_log "${fooFile}" | assert_match "die" "New line should have been returned."
   logmon_read_log "${fooFile}" | assert -l 0 "File did not change, why was data returned?"
   (
   cat <<EOF
ingloriously and without a struggle,
but let me first do some great thing...
EOF
   ) >> "${fooFile}"
   logmon_read_log "${fooFile}" | assert -l 2 "2 new lines were expected."
   cp /dev/null "${fooFile}"
   logmon_read_log "${fooFile}" | assert -l 0 "Nothing expected, existing log file was truncated."
   echo "that shall be told among men hereafter." >> "${fooFile}"
   logmon_read_log "${fooFile}" | assert_match "told" "1 new line was expected."
   echo "size decrease corruption" > "${fooFile}"
   logmon_read_log "${fooFile}" | assert -l 0 "File shrunk, new line should not be returned when corruption is detected."
   rm "${fooFile}"
   logmon_read_log "${fooFile}" 2>&1 | assert -l 0 "Missing files should not produce errors."
   echo "Hello World" > "${fooFile}"
   logmon_read_log "${fooFile}" | assert -l 0 "Expect new file behavior here, nothing should be returned."
   _logmonGenerateTestData 20
   logmon_read_log -max 1 "${fooFile}" | assert -l ">1000" "Maximum read size should limit amount of data returned."
   logmon_read_log -max 1 "${fooFile}" | assert -l 0 "Nothing expected, no new data was added to file after max read was invoked."
}

function logmon_handle_log {
   # Process input and scan it using a log handler.
   # >>> logmon_handle_log [-stdin] [-meta "X"] ["source_file"] "log_handler"
   # -stdin: Read log input from standard in.
   # -meta: Sets the meta value which can be referenced in the handler.
   # source_file: Source file containing the data we want to scan.
   # log_handler: The name of a log handler.
   ${arcRequireBoundVariables}
   debug3 "logmon_handle_log: $*"
   typeset log_handler x stdin line_count
   logmon_reset
   stdin=0
   while (( $# > 0)); do
      case "${1}" in
         "-stdin") stdin=1 ;;
         "-meta"|"-m") shift; _g_logmonMeta="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "logmon_handle_log" "(( $# <= 2 ))" "$*" && ${returnFalse}
   if (( ${stdin} )); then
      cat > "${_g_logmonBufferFile}0"
   else 
      log_file="${1}"
      file_raise_file_not_found "${log_file}" && ${returnFalse} 
      cat "${1}" > "${_g_logmonBufferFile}0"
      shift 
   fi
   log_handler="${1}"
   _configRaiseObjectNotFound "log_handlers" "${log_handler}" && ${returnFalse} 
   line_count=$(file_line_count "${_g_logmonBufferFile}0")
   counters_set "logmon,handle_log_line_count,+${line_count}"
   counters_set "logmon,handle_log_run_count,+1"
   timer_create -force -start "$$logmon"
   # This line actually executes the log handler in the current shell by sourcing it in.
   eval "$(config_load_object "log_handlers" "${log_handler}")"
   counters_set "logmon,handle_log_seconds,+$(timer_seconds "$$logmon")"
   timer_delete "$$logmon"
   find "${_logmonDir}" -type f -name "$$*" -exec rm {} \;
}

function logmon_extract {
   # Remove matching lines from a buffer and return to standard out or copy to a new buffer.
   # >>> logmon_extract [-ignore_case, -i] [-from,-f "X"] [-to,-t "X"] ["regex"]
   # -ignore_case: Ignore case.
   # -from: Buffer id to extract lines from. Defaults to buffer "0".
   # -to: Buffer id to copy extracted lines to. Defaults to standard out.
   # regex: Regular expression used to identify extracted lines. Defaults to all lines.
   ${arcRequireBoundVariables}
   debug3 "logmon_extract: $*"
   typeset ignore_case from_buffer_id to_buffer_id regex 
   ignore_case=0
   from_buffer_id="0"
   to_buffer_id="STDOUT"
   regex=".*"
   while (( $# > 0)); do
      case "${1}" in
         "-ignore_case"|"-i") ignore_case=1 ;;
         "-from"|"-f") shift; from_buffer_id="$(str_to_key_str "${1}")" ;;
         "-to"|"-t") shift; to_buffer_id="$(str_to_key_str "${1}")" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "logmon_extract" "(( $# <= 1 ))" "$*" && ${returnFalse}
   (( $# == 1 )) && regex="${1}"
   if [[ "${to_buffer_id}" == "STDOUT" ]]; then
      _logmonGrep ${ignore_case} "${from_buffer_id}" "${regex}"
   else
      _logmonGrep ${ignore_case} "${from_buffer_id}" "${regex}" > "${_g_logmonBufferFile}${to_buffer_id}"
   fi
   _logmonRemove ${ignore_case} "${from_buffer_id}" "${regex}"
   ${returnTrue} 
}

function test_logmon_extract {
   ls "${arcHome}/sh/core" > "${_g_logmonBufferFile}0"
   logmon_extract "awk" | assert_match "awk" "Should return awk lines during extract."
   logmon_grep | assert_nomatch "awk" "Awk lines should not appear after they have been extracted."
   ls "${arcHome}/sh/core" > "${_g_logmonBufferFile}0"
   logmon_extract "arcshell_a.*
arcshell_b.*|arcshell_c.*
arcshell_d.*
" | assert_nomatch "arcshell_cron.sh|arcshell_datetime.sh" "Values should not appear in output." 
}

function logmon_grep {
   # Returns matching lines to standard out.
   # >>> logmon_grep [-ignore_case, -i] [-from,-f "X"] ["regex"]
   # -ignore_case: Ignore case.
   # -from: Buffer id to extract lines from.
   # regex:
   ${arcRequireBoundVariables}
   debug3 "logmon_grep: $*"
   typeset ignore_case from_buffer_id regex  
   ignore_case=0
   from_buffer_id="0"
   regex=".*"
   while (( $# > 0)); do
      case "${1}" in
         "-ignore_case"|"-i") ignore_case=1 ;;
         "-from"|"-f") shift; from_buffer_id="$(str_to_key_str "${1}")" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "logmon_grep" "(( $# <= 1 ))" "$*" && ${returnFalse}
   (( $# == 1 )) && regex="${1}"
   if _logmonGrep ${ignore_case} "${from_buffer_id}" "${regex}"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test_logmon_grep {
   ls "${arcHome}/sh/core" > "${_g_logmonBufferFile}0"
   logmon_grep | assert -l ">30" "Buffer0 should contain the list of all files."
   logmon_grep -from "1" | assert -l 0 "Buffer 1 does not exist and should return zero lines."
   logmon_grep "arcshell_str.sh" | assert -l 1 "regex expression limits buffer return to one line."
}

function _logmonGrep {
   # Returns matching lines to standard out from a buffer.
   # >>> _logmonGrep ignore_case "from_buffer_id" "regex"
   ${arcRequireBoundVariables}
   debug3 "_logmonGrep: $*"
   typeset from_buffer_id regex ignore_case
   ignore_case=${1}
   from_buffer_id=${2}
   regex="$(echo "${3:-.*}" | utl_remove_blank_lines -stdin | str_to_csv "|")"
   if (( ${ignore_case} )); then
      ignore_case="-i"
   else
      ignore_case=
   fi
   file_raise_file_not_found "${_g_logmonBufferFile}${from_buffer_id}" && ${returnFalse} 
   egrep ${ignore_case:-} "${regex}" "${_g_logmonBufferFile}${from_buffer_id}"
   ${returnTrue} 
}

function logmon_write {
   # Used in a handler to write standard input to the specified buffer.
   # >>> logmon_write [-buffer,-b "X"] [buffer_id]
   # -buffer: The buffer number to write to.
   # buffer_id: Also the buffer number to write to.
   ${arcRequireBoundVariables}
   typeset buffer_id
   debug3 "logmon_write: $*"
   buffer_id=0
   while (( $# > 0)); do
      case "${1}" in
         "-buffer"|"-b") shift; buffer_id=${1} ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "logmon_write" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   (( $# == 1 )) && buffer_id=${1}
   if (( ${buffer_id} == 0 )); then
      _logmonThrowError "You can't over-write the zero buffer: $*: logmon_write"
      ${returnFalse} 
   fi
   cat > "${_g_logmonBufferFile}${buffer_id}"
   ${returnTrue} 
}

function logmon_remove {
   # Used in a handler to remove matching lines from the specified buffer.
   # >>> logmon_remove [-ignore_case,-i] [-from,-f "X"] ["regex"]
   # -ignore_case: Ignore case.
   # -from: Buffer id to remove lines from.
   # regex: Regular expression. Defaults to all lines.
   ${arcRequireBoundVariables}
   debug3 "logmon_remove: $*"
   typeset ignore_case from_buffer_id regex 
   ignore_case=0
   from_buffer_id="0"
   regex=".*"
   while (( $# > 0)); do
      case "${1}" in
         "-ignore_case"|"-i") ignore_case=1 ;;
         "-from"|"-f") shift; from_buffer_id="$(str_to_key_str "${1}")" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "logmon_remove" "(( $# <= 1 ))" "$*" && ${returnFalse}
   (( $# == 1 )) && regex="${1}"
   if _logmonRemove ${ignore_case} "${from_buffer_id}" "${regex}"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test_logmon_remove {
   ls "${arcHome}/sh/core" > "${_g_logmonBufferFile}0"
   logmon_grep | assert_match "awk" "Buffer0 should contain lines with 'awk'."
   logmon_remove "awk"
   logmon_grep | assert_nomatch "awk" "Lines with 'awk' should have been removed from Buffer0."
   logmon_remove 
   logmon_grep | assert -l 0 "Buffer0 should be empty."
}

function _logmonRemove {
   # Used in a handler to remove matching lines from the specified buffer.
   # >>> _logmonRemove ignore_case "from_buffer_id" "regex"
   ${arcRequireBoundVariables}
   typeset ignore_case from_buffer_id regex
   debug3 "_logmonRemove: $*"
   ignore_case=${1}
   from_buffer_id=${2}
   regex="$(echo "${3:-.*}" | utl_remove_blank_lines -stdin | str_to_csv "|")"
   if (( ${ignore_case} )); then
      ignore_case="-i"
   else
      ignore_case=
   fi
   if [[ -f "${_g_logmonBufferFile}${from_buffer_id}" ]]; then
      # -v inverts the match so no matching lines are returned.
      egrep ${ignore_case:-} -v "${regex}" "${_g_logmonBufferFile}${from_buffer_id}" > "${_g_logmonBufferFile}${from_buffer_id}~"
      # cat and rm works with Windows mounted disks, while mv is not certain. 
      cat "${_g_logmonBufferFile}${from_buffer_id}~" > "${_g_logmonBufferFile}${from_buffer_id}"
      rm "${_g_logmonBufferFile}${from_buffer_id}~"
   fi
}

function logmon_meta_value {
   # Used in a handler to return the value of the '-meta' argument.
   # >>> logmon_meta_value 
   ${arcRequireBoundVariables}
   echo "${_g_logmonMeta:-}"
}

function logmon_forget_file {
   # Remove the object library reference to a file.
   # >>> logmon_forget_file "filePath"
   ${arcRequireBoundVariables}
   debug3 "logmon_forget_file: $*"
   typeset fileKey
   fileKey="$(str_to_key_str "${1}")"
   objects_delete_temporary_object "logmon" "${fileKey}"  
   ${returnTrue} 
}

function _logmonProcessFile {
   # Process a file.
   # >>> _logmonProcessFile "filePath" "file_key"
   ${arcRequireBoundVariables}
   debug3 "_logmonProcessFile: $*"
   typeset filePath fileKey
   filePath="${1}"
   fileKey="${2}"
   eval "$(objects_load_object "logmon" "${fileKey}")"
   if [[ "${_logmonSizePlusMinusEqual}" == "+" ]]; then
      _logmonReturnLines "${filePath}" "${fileKey}"
   elif (( ${_logmonHeaderModifiedFlag} )); then
      debug3 "Log file header was modified: '${filePath}'"
   elif [[ "${_logmonSizePlusMinusEqual}" == "-" ]]; then
      debug3 "Log file shrunk: '${filePath}'"
   fi
}

function test__logmonProcessFile {
   :
}

function _logmonCheckSum {
   # Returns chksum from standard in.
   # >>> _logmonCheckSum [-stdin]
   if boot_is_program_found "cksum"; then
      cat | cksum | cut -d" " -f1
   else
      echo 0 
   fi
}

function _logmonUpdateFile {
   # Handles important calculations so we can take correct path of action later.
   # >>> _logmonUpdateFile "filePath" fileKey"
   ${arcRequireBoundVariables}
   debug3 "_logmonUpdateFile: $*"
   typeset filePath fileKey lastHash nextReadSizeInBytes lastBytes
   filePath="${1}"
   fileKey="${2}"
   eval "$(objects_load_object "logmon" "${fileKey}")"
   lastBytes=${_logmonFileBytes}
   _logmonFileBytes=$(file_get_size "${filePath}")

   # Determine if the file size has decreased, increased or stayed the same.
   if (( ${_logmonFileBytes} < ${lastBytes} )); then
      _logmonSizePlusMinusEqual="-"
   elif (( ${_logmonFileBytes} > ${lastBytes} )); then
      _logmonSizePlusMinusEqual="+"
   else 
      _logmonSizePlusMinusEqual="="
   fi

   # Have first 50 lines of the file changed. This could indicate an entirely new file.
   lastHash=${_logmonHeaderHash}
   if (( $(head -50 "${filePath}" | wc -l) == 50 )); then
      _logmonHeaderHash=$(head -50 "${filePath}" | _logmonCheckSum | cut -d" " -f1)
   else 
      _logmonHeaderHash=0
   fi
   if (( ${_logmonHeaderHash} != ${lastHash} )); then
      _logmonHeaderModifiedFlag=1
   else
      _logmonHeaderModifiedFlag=0
   fi

   _logmonFileUpdateTime=$(dt_epoch)

   # Calculate the starting position of our next read operation, taking our max read into account.
   ((nextReadSizeInBytes=_logmonFileBytes-lastBytes))
   if (( ${nextReadSizeInBytes} < ${_logmonMaxReadBytes:-0} )); then
      _logmonStartingByte=${lastBytes}
   else 
      ((_logmonStartingByte=_logmonFileBytes-_logmonMaxReadBytes))
      debug3 "Log file read is limited by maximum read size of ${_logmonMaxReadBytes} bytes."
   fi
   objects_save_object "logmon" "${fileKey}"
}

function test__logmonUpdateFile {
   :
}

function _logmonReturnLines {
   # Return new lines from a file.
   # >>> _logmonReturnLines "filePath" "fileKey"
   ${arcRequireBoundVariables}
   typeset filePath fileKey
   filePath="${1}"
   fileKey="${2}"
   eval "$(objects_load_object "logmon" "${fileKey}")"
   if (( ${_logmonStartingByte} == 0 )); then
      # Skip 0 instead of 1 here.
      dd if="${filePath}" bs=1 skip=0 2> /dev/null
   else
      dd if="${filePath}" bs=${_logmonStartingByte} skip=1 2> /dev/null
   fi
}

function _logmonIsNewFileKey {
   # Return true if this is a new file.
   # >>> _logmonIsNewFileKey "file_key"
   ${arcRequireBoundVariables}
   typeset fileKey
   fileKey="${1}"
   if objects_does_temporary_object_exist "logmon" "${fileKey}"; then
      ${returnFalse} 
   else
      ${returnTrue} 
   fi
}

function test__logmonIsNewFileKey {
   _logmonIsNewFileKey "isnewkey$$" && pass_test || fail_test
}

function _logmonThrowError {
   # Basic error handler for this library.
   # >>> _logmonThrowError "errorText"
   # errorText: Error message.
   throw_error "arcshell_logmon.sh" "${1}"
}

function _logmonGenerateTestData {
   # Generate some test data.
   # >>> _logmonGenerateTestData
   ${arcRequireBoundVariables}
   typeset x i
   x=${1:-10}
   num_range 1 ${x} | while read i; do
      cat "${fooFile}" "${fooFile}" > "${fooFile}.$$"
      mv "${fooFile}.$$" "${fooFile}"
   done
   debug3 "_logmonGenerateTestData: $(ls -alrt "${fooFile}")"
}

function test_file_teardown {
   rm "${fooFile}"
}

