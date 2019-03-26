
# module_name="Watcher"
# module_about="Watches files, directories, processes and other things."
# module_version=1
# module_image="spotlight.png"
# copyright_notice="Copyright 2019 Arclogic Software"

_watchHome="${arcTmpDir}/_arcshell_watch"
mkdir -p "${_watchHome}"

md5sum_is_installed=0
boot_is_program_found "md5sum" && md5sum_is_installed=1
sha1sum_is_installed=0
boot_is_program_found "sha1sum" && sha1sum_is_installed=1
_watchErrors=

# ToDo: watch_list_dirs - List directories being watched and possible stats/metrics.

function test_function_setup {
   debug3 "Setting up test function."
   rm -rf "/tmp/foo"
   mkdir -p "/tmp/foo"
   log_truncate
}

function watch_file {
   # Watch one or more files or directories for changes.
   # >>> watch_file [-recurse,-r] [-hash,-h] [-LOOK,-L] [-look,-l] [-tags,-t "X,x"] [-include,-i "X"] [-exclude,-e "X"] [-stdin] [-watch "X"] "watch_key" ["file_list"]
   # -recurse: Recursively search any directories.
   # -hash: Adds sha1 or md5 hash to monitor file changes, tries sha1 first.
   # -look: Look. Compare file contents when a change is detected if the file is readable.
   # -LOOK: LOOK. **Only** examine the contents for changes, ignore file attributes.
   # -tags: Tags. Comma separated list of tags. One word per tag. Spaces will be removed.
   # -include: Limit files and directories to those matching this regular expression.
   # -exclude: Exclude files and directories that match this regular expression.
   # -stdin: Read files and directories from standard input. 
   # -watch: Name of a "file_list" config file which returns the list of files and directories to watch.
   # watch_key: A unique string used to identify this particular watch.
   # file_list: Comma separated list of files and/or directories.
   ${arcRequireBoundVariables}
   debug3 "watch_file: $*"
   typeset stdin recurse exclude_regex include_regex file_as_key file tags \
      tmpFile total_file_count cache_key do_hash do_look watch_file_error_count \
      deleted_count modified_count require_look arg_count watch_list 
   _watchErrors=
   recurse=0
   do_hash=0
   do_look=0
   require_look=0
   tags="tag"
   include_regex=".*"
   exclude_regex="dummy_regex"
   stdin=0
   arg_count=2
   watch_list=
   while (( $# > 0)); do
      case "${1}" in
         "-recurse"|"-r") recurse=1                            ;;
         "-hash"|"-h") do_hash=1                               ;;
         "-LOOK"|"-L") do_look=1; require_look=1               ;;
         "-look"|"-l") do_look=1                               ;;
         "-tags"|"-t") shift; tags="$(utl_format_tags "${1}")" ;;
         "-include"|"-i") shift; include_regex="${1}"          ;;
         "-exclude"|"-e") shift; exclude_regex="${1}"          ;;
         "-stdin") stdin=1 ; arg_count=1                       ;;
         "-watch"|"-w") shift; watch_list="${1}"; arg_count=1  ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "watch_file" "(( $# >= ${arg_count} ))" "$*" && ${returnFalse} 

   watch_key="${1}"
   cache_key="watch_file_${watch_key}"
   timer_create -force -start "${cache_key}"

   # Creates the initial list of files and directories in sorted order.
   tmpFile="$(mktempf)"
   touch "${tmpFile}.stderr"
 
   debug3 "Reading file list."
   (
   if [[ -n "${watch_list:-}" ]]; then
      _configRaiseObjectNotFound "file_lists" "${watch_list}" && ${returnFalse} 
      eval "$(config_load_object "file_lists" "${watch_list}")" | utl_remove_blank_lines -stdin 
   elif (( ${stdin} )); then
      cat | str_split_line -stdin "," | str_remove_ticks_and_quotes -stdin | utl_remove_blank_lines -stdin 
   else
      echo "${2:-}" | str_split_line -stdin "," | utl_remove_blank_lines -stdin 
   fi
   ) | sort > "${tmpFile}"

   debug3 "*** tmpFile 1 ***"
   cat "${tmpFile}" | debugd2

   _watchFileExpandDirsInTmpFile "${tmpFile}" ${recurse} "${include_regex}" "${exclude_regex}"
   
   total_file_count=$(cat "${tmpFile}" | wc -l)

   # At this point we have the complete list of files we need to monitor.
   if (( ${do_look} )) && ! sensor_exists -g "${cache_key}" "${cache_key}"; then
      _watchFileCacheFileContents "${cache_key}" "${tmpFile}"
   fi

   _watchFileAddMetaDataToTmpFile "${tmpFile}" "${do_hash}" 

   modified_count=0
   while read file; do
      file_as_key="$(str_to_key_str "${file}")"
      if ! (( ${require_look} )); then
         ((modified_count=modified_count+1))
         log_notice \
            -logkey "watch_file" \
            -tags "${tags},modified" \
            "The file '${file}' has been modified."
         if (( ${do_look} )); then
            _watchFileWereFileContentsModified "${file}" "${cache_key}" "${tags}"
         fi 
      else 
         if _watchFileWereFileContentsModified "${file}" "${cache_key}" "${tags}"; then
            ((modified_count=modified_count+1))
         fi
      fi
   done < <(_watchReturnModifiedOrNewFiles "${cache_key}" "${tmpFile}")

   deleted_count=0
   while read file; do
      file_as_key="$(str_to_key_str "${file}")"
      ((deleted_count=deleted_count+1))
      log_notice \
         -logkey "watch_file" \
         -tags "${tags},deleted" \
         "The file '${file}' has been deleted."
   done < <(_watchFileReturnDeletedFiles "${cache_key}" "${tmpFile}")

   watch_file_error_count=$(cat "${tmpFile}.stderr" | wc -l)
   _watchFileLogErrors "${watch_key}" "${tmpFile}.stderr" "${tags}"

   counters_set "watch_file,run_count,+1"
   counters_set "watch_file,run_seconds,+$(timer_seconds "${cache_key}")"
   counters_set "watch_file,files_processed,+${total_file_count}"
   counters_set "watch_file,files_deleted,+${deleted_count}"
   counters_set "watch_file,files_modified,+${modified_count}"
   counters_set "watch_file,errors,+${watch_file_error_count}"
   
   timer_delete "${cache_key}"

   rm "${tmpFile}.stderr"

   rm "${tmpFile}"*

   if (( ${modified_count} || ${deleted_count} )); then
      sensor_get_last_diff -g "${cache_key}" "${cache_key}" | \
      log_info -stdin -logkey "watch_file" -tags "${tags}" "Here's what changed..."
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test_use_of_quotes_in_heredoc {
   watch_file_delete "foo"
   log_truncate
   date > "/tmp/foo/$$"
   (
   cat <<EOF
"/tmp/foo"
EOF
   ) | watch_file -stdin -hash "foo"
   log_get 20 | assert_nomatch "NOTICE"
   sleep 1
   date > "/tmp/foo/$$"
   (
   cat <<EOF
"/tmp/foo"
EOF
   ) | watch_file -stdin -hash "foo"
   log_get 20 | assert_match "NOTICE"
   watch_file_delete "foo"
   log_truncate
   date > "/tmp/foo/$$"
   (
   cat <<EOF
'/tmp/foo'
EOF
   ) | watch_file -stdin -hash "foo"
   log_get 20 | assert_nomatch "NOTICE"
   sleep 1
   date > "/tmp/foo/$$"
   (
   cat <<EOF
'/tmp/foo'
EOF
   ) | watch_file -stdin -hash "foo"
   log_get 20 | assert_match "NOTICE"
}

function test_monitor_a_directory {
   watch_file_delete "foo"
   ! watch_file "foo" "/tmp/foo" && pass_test || fail_test "Return false the first time a file or directory is checked."
   date > "/tmp/foo/$$"
   log_truncate
   watch_file "foo" "/tmp/foo" && pass_test || fail_test "Return true when a new file shows up in the directory."
   log_get 20 | assert_match "NOTICE.*$$.*" "New files are logged as a NOTICE in the application log."
   ! watch_file "foo" "/tmp/foo" && pass_test || fail_test "Nothing changed, should return false."
   log_truncate
   rm "/tmp/foo/$$"
   watch_file -tags "bar,xor" "foo" "/tmp/foo" && pass_test || fail_test "Deleted file should cause watch_file to return true."
   log_get 20 | assert_match "NOTICE.*$$.*deleted.*" "Deleted files are logged as a NOTICE in the application log."
   ! watch_file "foo" "/tmp/foo" && pass_test || fail_test "Nothing changed, should return false."
   mkdir -p "/tmp/foo/recursion"
   ! watch_file "foo" "/tmp/foo" && pass_test || fail_test "New directory 'recursion' does not return true."
   touch "/tmp/foo/recursion/$$.txt"
   log_truncate
   ! watch_file "foo" "/tmp/foo" && pass_test || fail_test "New file in 'recursion' is not found since -r flag not used.."
   log_truncate
   watch_file -r "foo" "/tmp/foo" && pass_test || fail_test "New file in 'recursion' is found since -r flag is used."
   rm -rf "/tmp/foo/recursion"
}

function test_monitor_a_file {
   watch_file_delete "foo"
   log_truncate
   date > "/tmp/foo/$$"
   ! watch_file "foo" "/tmp/foo/$$" && pass_test || fail_test "Should return false the first time a watch is run."
   log_get 20 | egrep -v "DATA" | assert -l 0 "Log should be empty with the exception of the DATA record."
   log_truncate
   date >> "/tmp/foo/$$"
   watch_file "foo" "/tmp/foo/$$" && pass_test || fail_test "File has been modified, should return true."
   log_get 20 | egrep "NOTICE|^! >" | assert -l ">=2"
   ! watch_file "foo" "/tmp/foo/$$" && pass_test || fail_test "Return true when file is static."
   rm "/tmp/foo/$$"
   log_truncate
   watch_file "foo" "/tmp/foo/$$" && pass_test || fail_test "Return true when file is deleted."
   log_get 20 
}

function test_look_file {
   watch_file_delete "foo"
   date > "/tmp/foo/$$"
   ! watch_file -look "foo" "/tmp/foo/$$" && pass_test || fail_test "Return false the first time file is checked."
   log_truncate
   echo "foo bar" >> "/tmp/foo/$$"
   debug_set_output 2
   watch_file -look "foo" "/tmp/foo/$$" && pass_test || fail_test
   debug_set_output 0
   log_get 100 | assert_match "foo.*bar"
}

function test_look_directory {
   watch_file_delete "foo"
   date > "/tmp/foo/$$_1"
   date > "/tmp/foo/$$_2"
   ! watch_file -look "foo" "/tmp/foo" && pass_test || fail_test 
   log_truncate
   echo "foo bar" >> "/tmp/foo/$$_2"
   watch_file -look "foo" "/tmp/foo" && pass_test || fail_test 
   log_get 20 | assert_match "foo.*bar"
}

function test_include_on_a_directory {
   watch_file_delete "foo"
   date > "/tmp/foo/$$_bar"
   date > "/tmp/foo/$$_zak"
   ! watch_file -look -include "zak" "foo" "/tmp/foo" && pass_test || fail_test 
   log_truncate
   date >> "/tmp/foo/$$_bar"
   date >> "/tmp/foo/$$_zak"
   watch_file -look -include "zak" "foo" "/tmp/foo" && pass_test || fail_test 
   log_get 20 | assert_nomatch "bar"
   log_get 20 | assert_match "foo"
}

function test_exclude_on_a_directory {
   watch_file_delete "foo"
   date > "/tmp/foo/$$_bar"
   date > "/tmp/foo/$$_zak"
   ! watch_file -look -exclude "zak" "foo" "/tmp/foo" && pass_test || fail_test 
   log_truncate
   date >> "/tmp/foo/$$_bar"
   date >> "/tmp/foo/$$_zak"
   watch_file -look -exclude "zak" "foo" "/tmp/foo" && pass_test || fail_test 
   log_get 20 | assert_nomatch "zak"
   log_get 20 | assert_match "bar"
}

function test_require_look {
   # This is how it works when you don't use -LOOK.
   watch_file_delete "foo"
   echo "foo" > "/tmp/foo/$$_bar"
   ! watch_file "foo" "/tmp/foo" && pass_test || fail_test 
   assert_sleep 60
   echo "foo" > "/tmp/foo/$$_bar"
   watch_file "foo" "/tmp/foo" && pass_test || fail_test 
   
   # Now use -LOOK.
   watch_file_delete "foo"
   echo "foo" > "/tmp/foo/$$_bar"
   ! watch_file -LOOK "foo" "/tmp/foo" && pass_test || fail_test 
   assert_sleep 60
   echo "foo" > "/tmp/foo/$$_bar"
   ! watch_file -LOOK "foo" "/tmp/foo" && pass_test || fail_test 
}

function test_stdin {
   watch_file_delete "foo"
   ! echo "/tmp/foo" | watch_file -stdin "foo" && pass_test || fail_test 
   date > "/tmp/foo/$$_bar"
   echo "/tmp/foo" | watch_file -stdin "foo" && pass_test || fail_test 
}

function _watchFileLogErrors {
   # Monitors for new errors as a result of running the commmand and logs them to the application log.
   # Note: Due to file permissions, temporary files and so on, errors may be expected.
   # >>> _watchFileLogErrors "watch_key" "errors_file" "tags"
   ${arcRequireBoundVariables}
   typeset watch_key cache_key errors_file tags 
   watch_key="${1}"
   cache_key="watch_file_${1}"
   errors_file="${2}"
   tags="${3:-"tags"}"
   if ! sensor_exists -group "${cache_key}" "errors_sensor"; then
      cat "${errors_file}" | sensor -group "${cache_key}" "errors_sensor"
      if [[ -s "${errors_file}" ]]; then
         cat "${errors_file}" | \
            log_notice -stdin -logkey "watch_file" -tags "${tags}" \
            "Errors observed while running watch_file. These may be expected."
      fi
   else
      if cat "${errors_file}" | sensor_check -group "${cache_key}" "errors_sensor"; then
         sensor_get_last_diff -group "${cache_key}" "errors_sensor" | \
            log_notice -stdin -logkey "watch_file" -tags "${tags}" \
            "The errors observed while running watch_file have changed."
      fi
   fi
}

function _watchFileWereFileContentsModified {
   # Logs information when the contents of a monitored file have modified and return true.
   # >>> _watchFileWereFileContentsModified "file" "cache_key" "tags"
   ${arcRequireBoundVariables}
   typeset file file_as_key cache_key tags 
   file="${1}"
   cache_key="${2}"
   tags="${3:-"tag"}"
   file_as_key="$(str_to_key_str "${file}")"
   if cat "${file}" | sensor_check -g "${cache_key}" "${file_as_key}"; then
      sensor_get_last_diff -group "${cache_key}" "${file_as_key}" | \
         log_notice -stdin -logkey "watch_file" -tags "${tags}" \
         "The contents of the file '${file}' have been modified."
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _watchFileExpandDirsInTmpFile {
   # Expands all of the directories in the temp file by listing the files in the directories and possible the subdirectories.
   # >>> _watchFileExpandDirsInTmpFile "tmpFile" "recurse" "include_regex" "exclude_regex"
   # tmpFile: Path to current tmpFile.
   # recurse: Recurse search directories for files.
   # include_regex: Only include objects which match this regular expression.
   # exclude_regex: Exclude objects which match this regular expression.
   ${arcRequireBoundVariables}
   debug3 "_watchFileExpandDirsInTmpFile: $*"
   typeset tmpFile recurse include_regex exclude_regex file_or_dir
   tmpFile="${1}"
   recurse="${2}"
   include_regex="${3}"
   exclude_regex="${4}"
   debug3 "r=${recurse}"
   (
   while read -r file_or_dir; do
      if [[ -d "${file_or_dir}" ]]; then
         if (( ${recurse} )); then
            find "${file_or_dir}" -type f 2>> "${tmpFile}.stderr"
            find "${file_or_dir}" -type f | debugd2
         else
            file_list_files -l "${file_or_dir}" 2>> "${tmpFile}.stderr"
         fi
      elif [[ -f "${file_or_dir}" ]]; then
         echo "${file_or_dir}"
      else 
         log_error -2 -logkey "watch" -tags "_watchFileExpandDirsInTmpFile" "Directory or file does not exist: ${file_or_dir}"
      fi
   done < "${tmpFile}"
   ) | egrep "${include_regex}" | egrep -v "${exclude_regex}" > "${tmpFile}2"
   mv "${tmpFile}2" "${tmpFile}"
   debug3 "*** tmpFile ***"
   cat "${tmpFile}" | debugd2 
}

function _watchFileCacheFileContents {
   # Initializes the sensor with the contents of each readable file.
   # >>> _watchFileCacheFileContents "cache_key" "tmpFile"
   ${arcRequireBoundVariables}
   typeset file cache_key tmpFile 
   cache_key="${1}"
   tmpFile="${2}"
   while read file; do
      if _watchFileIsFileLookable "${file}"; then
         file_as_key="$(str_to_key_str "${file}")"
         cat "${file}" | sensor_check -g "${cache_key}" "${file_as_key}"
      fi
   done < "${tmpFile}"
}

function watch_file_errors {
   # Return the last set of errors encoutered while running watch_file.
   # >>> watch_file_errors
   ${arcRequireBoundVariables}
   typeset cache_key
   cache_key="watch_file_${1}"
}

function _watchFileCacheExists {
   # Return true if the complete file list has been cached for the give cache_key.
   # >>> _watchFileCacheExists "cache_key"
   ${arcRequireBoundVariables}
   typeset cache_key 
   cache_key="${1}"
   if sensor_exists -g "${cache_key}" "${cache_key}"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _watchFileCopyCache {
   # Copy the cached file list so we have data to compare to after we update it.
   # >>> _watchFileCopyCache "cache_key"
   ${arcRequireBoundVariables}
   typeset cache_key 
   cache_key="${1}"
   cache_get -g "${cache_key}" "${cache_key}" | \
      cache_save -stdin -g "${cache_key}" "${cache_key}-"
}










function _watchFileIsFileLookable {
   # Return true if we can read the contents of a file for comparisons.
   # >>> _watchFileIsFileLookable "file"
   ${arcRequireBoundVariables}
   typeset file 
   file="${1}"
   if ! file_is_binary "${file}" && [[ -r "${file}" ]]; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test__watchFileIsFileLookable {
   :
}

function watch_file_delete {
   # Delete all of the cached data assocated with a watch_file key.
   # >>> watch_file_delete "watch_key"
   ${arcRequireBoundVariables}
   debug3 "watch_file_delete: $*"
   typeset cache_key
   cache_key="watch_file_${1}"
   cache_delete_group "${cache_key}" 
   sensor_delete_sensor_group "${cache_key}"
}

function _watchFileAddMetaDataToTmpFile {
   # Updates the tmpFile by adding meta data for each file listed in it.
   # >>> _watchFileAddMetaDataToTmpFile "tmpFile" "do_hash"
   ${arcRequireBoundVariables}
   debug3 "_watchFileAddMetaDataToTmpFile: $*"
   typeset tmpFile file do_hash 
   tmpFile="${1}"
   do_hash="${2}"
   (
   while read file; do
      _watchReturnFileMetaData "${file}" "${do_hash}" 2>> "${tmpFile}.stderr"
   done < "${tmpFile}"
   ) > "${tmpFile}2"
   mv "${tmpFile}2" "${tmpFile}"
   debug3 "_watchFileAddMetaDataToTmpFile: End"
   ${returnTrue} 
}

function test__watchFileAddMetaDataToTmpFile {
   :
}

function _watchReturnModifiedOrNewFiles {
   # Returns the full path to any modified or new files in a directory.
   # >>> _watchFileReturnNewFiles "cache_key" "tmpFile"
   ${arcRequireBoundVariables}
   debug3 "_watchReturnModifiedOrNewFiles: $*"
   typeset cache_key tmpFile 
   cache_key="${1}"
   tmpFile="${2}"
   if cat "${tmpFile}" | sensor_check -g "${cache_key}" "${cache_key}"; then 
      sensor_get_last_diff -g "${cache_key}" "${cache_key}" | \
         grep "^> " | str_get_last_word -stdin | uniq 
   fi
   ${returnTrue} 
}

function test__watchReturnModifiedOrNewFiles {
   :
}

function _watchFileReturnDeletedFiles {
   # Returns the full path to any deleted files in a directory.
   # >>> _watchFileReturnNewFiles "cache_key" "tmpFile"
   ${arcRequireBoundVariables}
   debug3 "_watchFileReturnDeletedFiles: $*"
   typeset cache_key tmpFile
   cache_key="${1}"
   sensor_get_last_diff -g "${cache_key}" "${cache_key}" | grep "^< " | \
      str_get_last_word -stdin | uniq | _watchFileFilterDeletedFile
   ${returnTrue} 
}

function test__watchFileReturnDeletedFiles {
   :
}

function _watchFileFilterDeletedFile {
   # Returns the files from standard input that do not exist.
   # >>> _watchFileFilterDeletedFile 
   typeset file 
   while read file; do
      [[ ! -f "${file}" ]] && echo "${file}"
   done
}

function _watchReturnFileMetaData {
   # Return the file attributes and possible sha1 or md5 hash for the file.
   # >>> _watchReturnFileMetaData "file" "do_hash" 
   typeset file do_hash 
   # debug3 "_watchReturnFileMetaData: $*"
   file="${1}"
   do_hash="${2}"
   ls -alrt "${file}" 
   debug3 "_watchReturnFileMetaData: ${file}; do_hash=${do_hash}"
   ! (( ${do_hash} )) && ${returnTrue} 
   if [[ -r "${file}" ]] && (( ${sha1sum_is_installed} )) ; then
      sha1sum "${file}"
   elif [[ -r "${file}" ]] && (( ${md5sum_is_installed} )); then
      md5sum "${file}"
   fi
   ${returnTrue} 
}

function test__watchReturnFileMetaData {
   :
}

function test_file_teardown {
   watch_file_delete "foo"
}


