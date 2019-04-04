
# module_name="Files"
# module_about="Simplifies many common file and directory related tasks."
# module_version=1
# module_image="file.png"
# copyright_notice="Copyright 2019 Arclogic Software"

_fileDir="${arcTmpDir}/_arcshell_file"
mkdir -p "${_fileDir}"

_fileTestFile="${_fileDir}/$$.test"

function __readmeFile {
   cat <<EOF
> I have not failed. I've just found 10,000 ways that won't work. -- Richard Pattis

# Files

**Simplifies many common file and directory related tasks.**
EOF
}

function __setupArcShellFile {
   _filePurgeFileModifiedHistory
   if boot_raise_program_not_found "perl"; then
      stderr_banner "Perl is required for the functions that return or use file modified time."
   fi
}

function file_remove_matching_lines_from_file {
   # Remove all matching lines from a file.
   # >>> file_remove_matching_lines_from_file "file_name" "regex"
   ${arcRequireBoundVariables}
   typeset tmpFile file_name regex
   file_name="${1}"
   regex="${2}"
   tmpFile="$(mktempf)"
   file_raise_file_not_found "${file_name}" && ${returnFalse} 
   egrep -v "${regex}" "${file_name}" > "${tmpFile}"
   mv "${tmpFile}" "${file_name}"
   ${returnTrue} 
}

function test_file_remove_matching_lines_from_file {
   typeset f 
   f="/tmp/$$pwd.tmp"
   cp "/etc/passwd" "${f}"
   cat "${f}" | assert_match "^${LOGNAME}:"
   file_remove_matching_lines_from_file "${f}" "^${LOGNAME}:" && pass_test || fail_test 
   cat "${f}" | assert_nomatch "^${LOGNAME}:"
   rm "${f}"
} 

function file_is_binary {
   # Return true if file is binary, false if not.
   # >>> file_is_binary "file"
   ${arcRequireBoundVariables}
   typeset file 
   file="${1:-}"
   utl_raise_invalid_option "file_is_binary" "(( $# ==1 ))" "$*" && ${returnFalse}  
   file_raise_file_not_found "${file}" && ${returnTrue} 
   [[ ! -s "${file}" ]] && ${returnFalse} 
   if boot_is_program_found "perl"; then
      if perl -E 'exit((-B $ARGV[0])?0:1);' "${file}"; then
         ${returnTrue} 
      else
         ${returnFalse} 
      fi
   else
      if (( $(diff "${file}" /etc/passwd | grep "Binary files" | wc -l) )); then
         ${returnTrue}
      else
         ${returnFalse} 
      fi
   fi
}

function test_file_is_binary {
   typeset tmpFile
   tmpFile="$(mktempf)"
   cp /dev/null "${tmpFile}"
   ! file_is_binary "${tmpFile}" && pass_test || fail_test 
   date > "${tmpFile}"
   ! file_is_binary "${tmpFile}" && pass_test || fail_test 
}

function file_modify_remove_lines {
   # Modifies file by removing matching lines.
   # file_modify_remove_lines "file" "regex"
   ${arcRequireBoundVariables}
   typeset file regex 
   file="${1}"
   regex="${2}"
   file_raise_file_not_found "${file}" && ${returnFalse} 
   tmpFile="$(mktempf)"
   cp -p "${file}" "${tmpFile}"
   if [[ -n "${regex}" ]]; then
      egrep -v "${regex}" "${file}" > "${tmpFile}"
   fi
   mv "${tmpFile}" "${file}"
}

function test_file_modify_remove_lines {
   cp "${arcHome}/sh/core/arcshell_file.sh" "/tmp/$$.test"
   cat "/tmp/$$.test" | assert_match "egrep"
   file_modify_remove_lines "/tmp/$$.test" "egrep"
   cat "/tmp/$$.test" | assert_nomatch "egrep"
}

function file_is_executable {
   # Return true if a file is executable.
   # >>> file_is_executable "file"
   ${arcRequireBoundVariables}
   typeset file 
   file="${1}"
   file_raise_file_not_found "${file}" && ${returnFalse}
   if [[ -x "${file}" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_file_is_executable {
   :
}

function file_get_ext {
   # Return the file extension to the best of our ability.
   # >>> file_get_ext "file"
   ${arcRequireBoundVariables}
   debug2 "file_get_ext: $*"
   typeset file baseName dots 
   file="${1}"
   baseName="$(basename "${file}")"
   dots=$(str_get_char_count "." "${baseName}")
   if (( ${dots} == 0 )); then
      :
   elif (( ${dots} == 1 )); then
      echo "${baseName}" | cut -d"." -f2
   else
      if (( $(echo "${baseName}" | egrep "\.tar\.gz$|\.tar\.Z$|\.tar\.zip$" | wc -l) )); then
         echo "${baseName}" | str_reverse_line -stdin | cut -d"." -f1-2 | str_reverse_line -stdin
      else
         echo "${baseName}" | str_reverse_line -stdin | cut -d"." -f1 | str_reverse_line -stdin
      fi
   fi
}

function test_file_get_ext {
   file_get_ext "/tmp/foo$$.txt" | assert "txt" 
   file_get_ext "/tmp/foo.tar.gz" | assert "tar.gz"
   file_get_ext "/tmp/foo.tar.x.gz" | assert "gz"
   file_get_ext "foo" | assert -l 0
}

function _file_get_file_root_name {
   # Returns the file name only (no extension).
   # >>> _file_get_file_root_name "file"
   ${arcRequireBoundVariables}
   debug2 "file_get_file_root_name: $*"
   typeset file baseName periods 
   file="${1}"
   baseName="$(basename "${file}")"
   periods=$(str_get_char_count "." "${baseName}")
   if (( ${periods} == 0 )); then
     echo "${baseName}"
   elif (( ${periods} == 1 )); then
      echo "${baseName}" | cut -d"." -f1
   else
      if (( $(echo "${baseName}" | egrep "\.tar\.gz$|\.tar\.Z$|\.tar\.zip$" | wc -l) )); then
         echo "${baseName}" | str_reverse_line -stdin | cut -d"." -f3- | str_reverse_line -stdin
      else
         echo "${baseName}" | str_reverse_line -stdin | cut -d"." -f2- | str_reverse_line -stdin
      fi
   fi
}

function file_get_file_root_name {
   # Return the file root name (strips path and extension).
   # >>> file_get_file_root_name [-stdin] | "file"
   ${arcRequireBoundVariables}
   typeset file
   if [[ "${1}" == "-stdin" ]]; then
      while read file; do
         _file_get_file_root_name "${file}"
      done < <(cat)
   else 
      _file_get_file_root_name "${1}"
   fi
}

function test_file_get_file_root_name {
   file_get_file_root_name "/tmp/foo$$.txt" | assert "foo$$" "Single extensions should return the root file name."
   file_get_file_root_name "/tmp/foo.tar.gz" | assert "foo" "Files with two extensions in which the first is 'tar' should include the tar in the extension part."
   file_get_file_root_name "/tmp/foo.tar.x.gz" | assert "foo.tar.x" "A file with 3 extensions should be viewed as having a single extenstion."
   file_get_file_root_name "foo" | assert "foo" "No extension should return raw input."
}


# function file_get_root_dir_from_tar_file {
#    #
#    # >>>
#    ${arcRequireBoundVariables}
#    typeset f r
#    f="${1}"
#    r="$(basename "$(tar -tf "${f}" | head -1 )")"
#    echo "${r}"
# }

# function test_file_get_root_dir_from_tar_file {
#    :
# }

# function file_get_root_dir_count_from_tar_file {
#    # 
#    # >>> 
#    ${arcRequireBoundVariables}
#    typeset f
#    f="${1}"
#    tar -tf "${f}" | grep "\/$" | grep -v "\/.*\/" | wc -l
# }

function file_raise_file_not_found {
   # Throw file not found error and return true if file is not found.
   # >>> file_raise_file_not_found "file"
   ${arcRequireBoundVariables}
   typeset file 
   file="${1}"
   if ! [[ -f "${file}" ]]; then
      _fileThrowError "File not found: $*: file_raise_file_not_found"
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_file_raise_file_not_found {
   :
}


function file_raise_dir_not_found {
   # Throw error and return true if directory is not found.
   # >>> file_raise_dir_not_found "directory"
   ${arcRequireBoundVariables}
   typeset directory 
   directory="${1}"
   if ! [[ -d "${directory}" ]]; then
      _fileThrowError "Directory not found: $*: file_raise_dir_not_found"
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_file_raise_dir_not_found {
   :
}


function file_is_dir_writable {
   # Return true if a directory is writable.
   # >>> file_is_dir_writable "directory"
   ${arcRequireBoundVariables}
   typeset directory
   directory="${1}"
   file_raise_dir_not_found "${directory}" && ${returnFalse} 
   if [[ -w "${directory}" ]]; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test_file_is_dir_writable {
   file_is_dir_writable "/tmp" && pass_test || fail_test 
   file_is_dir_writable "/var" 2>/dev/null && fail_test || pass_test 
   file_is_dir_writable "/notexist$$" 2>/dev/null && fail_test || pass_test 
   file_is_dir_writable "" 2>/dev/null && fail_test || pass_test 
}


function file_raise_dir_not_writable {
   # Throw error and return true if directory is not writable.
   # >>> file_raise_dir_not_writable
   ${arcRequireBoundVariables}
   typeset directory 
   directory="${1}"
   if ! file_is_dir_writable "${directory}"; then
      _fileThrowError "Directory is not writable: $*: file_raise_dir_not_writable"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test_file_raise_dir_not_writable {
   file_raise_dir_not_writable "/tmp" && fail_test || pass_test 
   file_raise_dir_not_writable "/var" 2>&1 | assert_match "ERROR"
}


function file_raise_is_not_full_path {
   # Throw error and return true if ```file``` is not the complete path to file.
   # >>> file_raise_is_not_full_path "file"
   ${arcRequireBoundVariables}
   typeset file 
   file="${1}"
   if ! file_is_full_path "${file}"; then
      _fileThrowError "Please provide the complete path to file: $*: file_raise_is_not_full_path"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test_file_raise_is_not_full_path {
   :
}


function file_raise_is_path {
   # Throws error and returns true if it appears the file includes the path.
   # >>> file_raise_is_path "file"
   ${arcRequireBoundVariables}
   typeset file 
   utl_raise_invalid_option "file_raise_is_path" "(( $# == 1 ))" "$*" && ${returnFalse} 
   file="${1}"
   if echo "${file}" | egrep "\\\\|\/" 1> /dev/null; then
      _fileThrowError "Expected file name only, not path: $*: file_raise_is_path"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test_file_raise_is_path {
   file_raise_is_path "/foo/bar/bin" && pass_test || fail_test 
   ! file_raise_is_path "foo" 2>/dev/null && pass_test || fail_test 
   file_raise_is_path 2>&1 | assert_match "ERROR"  
   file_raise_is_path "/foo" 2>&1 | assert_match "ERROR"  
}


function file_has_been_modified {
   # Return true if a file has been modified since last time checked. New files return false.
   # >>> file_has_been_modified "file"
   ${arcRequireBoundVariables}
   typeset file lastModifiedTime fileModifiedTime historyFile
   file="${1:-}"
   file_raise_file_not_found "${file}" && ${returnFalse}
   historyFile="${_fileDir}/fileModifiedHistory.dat"
   touch "${historyFile}"
   lastModifiedTime=$(grep "${file}" "${historyFile}" | cut -d":" -f2 | tail -1)
   fileModifiedTime=$(file_modified_time "${file}")
   if [[ -z "${lastModifiedTime:-}" ]]; then
      echo "${file}:${fileModifiedTime}" >> "${historyFile}"
      ${returnFalse} 
   elif (( ${lastModifiedTime} != ${fileModifiedTime} )); then
      echo "${file}:${fileModifiedTime}" >> "${historyFile}"
      ${returnTrue}
   else
      ${returnFalse} 
   fi
}

function test_file_has_been_modified {
   typeset f 
   f="/tmp/foo.txt"
   [[ -f "${f}" ]] && rm -rf "${f}" 
   _filePurgeFileModifiedHistory
   touch "${f}"
   ! file_has_been_modified "${f}" && pass_test || fail_test
   sleep 2
   date >> "${f}"
   file_has_been_modified "${f}" && pass_test || fail_test
   sleep 2
   ! file_has_been_modified "${f}" && pass_test || fail_test
   rm -rf "${f}"
   file_has_been_modified "${f}" 2>&1 | assert_match "ERROR"
   file_has_been_modified 2>&1 | assert_match "ERROR"
}


function _filePurgeFileModifiedHistory {
   # Remove references to files which do not exist from the history file.
   # >>> _filePurgeFileModifiedHistory
   ${arcRequireBoundVariables}
   typeset file historyFile
   tmpFile="$(mktempf)"
   historyFile="${_fileDir}/fileModifiedHistory.dat"
   touch "${historyFile}"
   while read x; do 
      file="$(echo "${x}" | cut -d":" -f1)"
      [[ -f "${file}" ]] && echo "${x}" >> "${tmpFile}"
   done < "${historyFile}"
   mv "${tmpFile}" "${historyFile}"
}

function test__filePurgeFileModifiedHistory {
   :
}


function file_create_file_of_size {
   # Create a ```file``` of ```bytes```.
   # >>> file_create_file_of_size "file" bytes
   ${arcRequireBoundVariables}
   typeset file bytes
   file="${1}"
   bytes="${2}"
   if [[ ! -f "${file}" ]]; then
      dd if=/dev/zero of="${file}" bs=${bytes} count=1 
      if [[ ! -f "${file}" ]]; then
         _fileThrowError "Failed to create file: $*: file_create_file_of_size"
      fi
   else
      _fileThrowError "Can't overwrite existing file: $*: file_create_file_of_size"
   fi
}

function test_file_create_file_of_size {
   tmpDir="$(mktempd)"
   file_get_dir_mb_size "${tmpDir}" | assert 0
   file_create_file_of_size "${tmpDir}/foo" 10240000 
   if boot_is_sunos; then
      assert_banner "Solaris size will report 0 if we don't wait a few seconds..."
      assert_sleep 5
   fi
   file_get_dir_mb_size "${tmpDir}" | assert ">8"
   rm -rf "${tmpDir}"
}


function file_get_owner {
   # Return the owner of a file. Also reads file names from standard input.
   # >>> file_get_owner "file"
   ${arcRequireBoundVariables}
   typeset file x
   if [[ -z "${1:-}" ]]; then
      while read -r x; do
         file_get_owner "${x}"
      done
   else 
      file="${1}"
      ls -l "${file}" | ${arcAwkProg} '{print $3}'
   fi
}

function test_file_get_owner {
   touch "/tmp/$$"
   file_get_owner "/tmp/$$" | assert "${LOGNAME}"
   rm "/tmp/$$"
   file_get_owner "/etc/passwd" | assert "root"
}

function file_join_path {
   # Joins path strings together and returns a single path.
   # >>> file_join_path "string1" "string2" ...
   if [[ -d "${1}" ]]; then
      printf "${1}"
   else
      printf "./$(echo "${1}" | str_to_key_str)"
   fi
   shift
   while (( $# > 0 )); do
      if [[ -d "${1}" ]]; then
         printf "/${1}"
      else
         printf "/$(echo "${1}" | str_to_key_str)"
      fi
      shift
   done
   printf "\n"
}

function test_file_join_path {
   file_join_path "/tmp" "foo bar" | assert "/tmp/foo_bar"
   file_join_path "/tmp" "foo bar" "baz" | assert "/tmp/foo_bar/baz"
   file_join_path "yak" "foo bar" "baz" | assert "./yak/foo_bar/baz"
}

function file_line_count {
   # Return the number of lines in a file.
   # >>> file_line_count "file"
   ${arcRequireBoundVariables}
   typeset file
   file="${1}"
   wc -l < "${file}" 
}

function test_file_line_count {
   touch "foo.lc"
   file_line_count "foo.lc" | assert 0
   date >> "foo.lc"
   file_line_count "foo.lc" | assert 1
   rm "foo.lc"
}

function file_realpath {
   # Return full path from relative path if possible. Must be able to 'cd' to the dir.
   # >>> file_realpath "file"
   ${arcRequireBoundVariables}
   typeset file x d b
   file="${1}"
   if file_raise_file_not_found "${file}"; then
      echo "${file}" && ${returnFalse} 
   fi
   if boot_is_program_found "realpath"; then
      realpath "${file}"
   else 
      x="$(pwd)"
      d="$(dirname "${file}")"
      if ! [[ -d "${d}" ]]; then
         echo "${file}" && ${returnFalse} 
      fi
      if ! cd "${d}"; then
         echo "${file}" && ${returnFalse} 
      fi
      b="$(basename "${file}")"
      echo "$(pwd)/${b}"
      cd "${x}"
   fi
   ${returnTrue} 
}

function test_file_realpath {
   :
}

function file_is_full_path {
   # Return true if the provided file path is full path to the file.
   # >>> file_is_full_path "file"
   ${arcRequireBoundVariables}
   typeset file 
   file="${1}"
   if [[ "${file:0:1}" == '/' && -f "${file}" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi 
}

function test_file_is_full_path {
   touch test.$$
   $(file_is_full_path "$(pwd)/test.$$") && pass_test || fail_test
   $(file_is_full_path test.$$) && fail_test || pass_test
   rm test.$$
}

function file_are_files_same {
   # Return true if diff command returns zero lines.
   # >>> file_are_files_same "file1" "file2"
   typeset x file1 file2 
   file1="${1}"
   file2="${2}"
   if [[ -f "${file1}" && -f "${file2}" ]]; then
      x=$(diff "${file1}" "${file2}" 2> /dev/null | wc -l)
      if (( ${x} == 0 )); then
         ${returnTrue}
      else
         ${returnFalse}
      fi
   else
      _fileThrowError "File(s) not found: $*: file_are_files_same"
      ${returnFalse}
   fi
}

function test_file_are_files_same {
   touch "foo.df"
   ! $(file_are_files_same "foo.df" "foo.lc") && pass_test || fail_test
   cp /dev/null "foo.lc" 
   $(file_are_files_same "foo.df" "foo.lc") && pass_test || fail_test
   date > "foo.df" && cp "foo.df" "foo.lc"
   $(file_are_files_same "foo.df" "foo.lc") && pass_test || fail_test
   rm "foo.df" "foo.lc"
}

function file_modified_time {
   # Returns file modified time in Unix epoch seconds.
   # >>> file_modified_time "file_name"
   ${arcRequireBoundVariables}
   typeset file_name modifiedTime
   file_name="${1}"
   if $(boot_is_program_found "perl"); then
      if [[ ! -f "${file_name}" ]]; then
         _fileThrowError "File not found: $*: file_modified_time"
      else
         modifiedTime=$(perl -e '$x = (stat("'$file_name'"))[9]; print "$x\n";')
         echo ${modifiedTime}
      fi
   else
      _fileThrowError "Perl is required to run this function: $*: file_modified_time"
   fi
}

function test_file_modified_time {
   typeset x
   touch "${_fileTestFile}"
   assert_sleep 1
   x=$(dt_epoch)
   file_modified_time "${_fileTestFile}" | assert "<${x}"
   assert_sleep 1
   touch "${_fileTestFile}"
   file_modified_time "${_fileTestFile}" | assert ">${x}"
}

function file_seconds_since_modified {
   # Returns number of seconds since file was last modified.
   # 
   # > Requires perl.
   # 
   # >>> file_seconds_since_modified "file_name"
   ${arcRequireBoundVariables}
   typeset file_name secondsSinceModifiedTime
   if $(boot_is_program_found "perl"); then 
      file_name="${1}"
      secondsSinceModifiedTime=$(perl -e '$x = time - (stat("'$file_name'"))[9]; print "$x\n";')
      echo ${secondsSinceModifiedTime}
   else
      _fileThrowError "Perl is required to run this function: $*: file_seconds_since_modified"
   fi
}

function test_file_seconds_since_modified {
   file_seconds_since_modified "${_fileTestFile}" | assert "<60"
   touch "${_fileTestFile}"
   file_seconds_since_modified "${_fileTestFile}" | assert "<5"
   assert_sleep 2
   file_seconds_since_modified "${_fileTestFile}" | assert ">1"
}

function file_is_empty_dir {
   # Return true if directory is empty.
   # >>> file_is_empty_dir "directory"
   ${arcRequireBoundVariables}
   typeset x
   if [[ -d "${1:-}" ]]; then
      x=$(ls "${1}" | wc -l)
      if (( ${x} == 0 )); then
         ${returnTrue}
      else
         ${returnFalse}
      fi
   else
      _fileThrowError "Directory not found: $*: file_is_empty_dir"
   fi
}

function test_file_is_empty_dir {
   d="/tmp/foo"
   rm -rf "${d}"
   mkdir "${d}"
   file_is_empty_dir "${d}" && pass_test || fail_test
   touch "${d}/foo"
   ! file_is_empty_dir "${d}" && pass_test || fail_test
   rm "${d}/foo"
   mkdir "${d}/foo"
   ! file_is_empty_dir "${d}" && pass_test || fail_test
}

function file_try_mkdir {
   # Try to make a directory and return false if unable.
   # >>> file_try_mkdir "directory"
   ${arcRequireBoundVariables}
   typeset directory
   directory="${1}"
   if $(mkdir -p ${directory}); then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_file_try_mkdir {
   typeset d
   d="/tmp/dir$$"
   rm -rf "${d}" 2> /dev/null
   file_try_mkdir "${d}" && pass_test || fail_test
   file_is_dir "${d}" && pass_test || fail_test
   ! file_try_mkdir "/x/${d}" 2> /dev/null && pass_test || fail_test
   rm -rf "${d}"
}

function file_list_files {
   # Return files in a directory. Does not include subdirectories.
   # >>> file_list_files [-l|-a] "directory"
   # -l: List full path to file.
   # -a: List all attributes.
   ${arcRequireBoundVariables}
   typeset directory return_full_path return_attributes file
   return_full_path=0
   return_attributes=0
   while (( $# > 0)); do
      case "${1}" in
         "-l") return_full_path=1 ;;
         "-a") return_attributes=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "file_list_files" "(( $# == 1 ))" "$*" && ${returnFalse}
   directory="${1}"
   file_raise_dir_not_found "${directory}" && ${returnFalse} 
   (
   if (( ${return_full_path} )); then
      while read file; do
         if [[ -f "${file}" ]]; then
            if (( ${return_attributes} )); then
               ls -alt "${file}"
            else
               echo "${file}"
            fi
         fi
      done < <(find "${directory}/." -name . -o -type d -prune -o -print | sed 's/\/\.\//\//')
   else
      while read file; do
         if [[ -f "${directory}/${file}" ]]; then
            if (( ${return_attributes} )); then
               ls -alt "${directory}/${file}"
            else
               echo "${file}"
            fi
         fi
      done < <(ls -a "${directory}")
   fi
   ) | sort
}

function test_file_list_files {
   :
}

function file_list_dirs {
   # List directory names, not full paths, from specified or current directory. 
   # >>> file_list_dirs "directory"
   ${arcRequireBoundVariables}
   typeset directory
   directory="${1:-}"
   [[ -z "${directory}" ]] && directory="$(pwd)"
   ls -al "${directory}" | grep "^d" | str_get_last_word -stdin | egrep -v "\.|\.\."
}

function test_file_list_dirs {
   rm -rf "/tmp/x"
   mkdir -p "/tmp/x/a"
   mkdir -p "/tmp/x/b"
   file_list_dirs "/tmp/x" | wc -l | assert 2
   cd /tmp/x
   file_list_dirs | wc -l | assert 2
   cd /tmp
}

function file_is_dir {
   # Return true if the directory exists.
   # >>> file_is_dir "directory"
   ${arcRequireBoundVariables}
   typeset directory
   directory="${1:-}"
   if [[ -d "${directory}" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_file_is_dir {
   ! file_is_dir && pass_test || fail_test
   file_is_dir "/tmp" && pass_test || fail_test
   ! file_is_dir "/does_not_exist" && pass_test || fail_test
   ! file_is_dir /etc/passwd && pass_test || fail_test
}

function file_get_dir_kb_size {
   # Returns size of directory contents in kilobytes.
   #
   # > Errors are suppressed to account for busy directories.
   # > If you lack correct perms size may not be accurate.
   #
   # >>> file_get_dir_kb_size "directory"
   ${arcRequireBoundVariables}
   typeset directory x
   directory="${1}"
   x=$(du -sk "${directory}" 2> /dev/null | ${arcAwkProg} '{print $1}' | tail -1)
   debug2 "size=${x}, directory=${directory}: file_get_dir_kb_size"
   du -sk "${directory}" | debugd2
   ls -alrt "${directory}" | debugd2 
   du -sk "${directory}" | debugd2
   echo ${x}
}

function test_file_get_dir_kb_size {
   tmpDir="$(mktempd)"
   file_create_file_of_size "${tmpDir}/foo" 1024000
   if boot_is_sunos; then
      assert_banner "Solaris size will report 0 if we don't wait a few seconds..."
      assert_sleep 5
   fi
   file_get_dir_kb_size "${tmpDir}" | assert ">800"
   rm -rf "${tmpDir}"
}

function file_get_mb_from_kb {
   # Read kilobytes from input and return megabytes. 
   # >>> file_get_mb_from_kb [-stdin]
   ${arcRequireBoundVariables}
   typeset x m
   if [[ "${1:-}" == "-stdin" ]]; then
      while read x; do
         ((m=${x}/1024))
         #debug2 "${m}mb: file_get_mb_from_kb"
         echo ${m}
      done
    else
       echo "${1}" | file_get_mb_from_kb -stdin
   fi
}

function test_file_get_mb_from_kb {
   file_get_mb_from_kb "8192" | assert 8 
   echo 8192 | file_get_mb_from_kb -stdin | assert 8 
}

function file_get_dir_mb_size {
   # Get dir size, returns mbytes.
   # >>> file_get_dir_mb_size "directory"
   ${arcRequireBoundVariables}
   typeset directory
   #debug3 "file_get_dir_mb_size: $*"
   directory="${1}"
   echo $(file_get_mb_from_kb $(file_get_dir_kb_size "${directory}"))
}

function test_file_get_dir_mb_size {
   tmpDir="$(mktempd)"
   file_create_file_of_size "${tmpDir}/foo" 7000000
   if boot_is_sunos; then
      assert_banner "Solaris size will report 0 if we don't wait a few seconds..."
      assert_sleep 5
   fi
   file_get_dir_mb_size "${tmpDir}" | assert ">5"
   rm -rf "${tmpDir}"
}

function file_get_size {
   # Return file size in bytes.
   # >>> file_get_size "file"
   ${arcRequireBoundVariables}
   typeset file bytes
   file="${1:-}"
   file_raise_file_not_found "${file}" && ${returnFalse} 
   bytes=$(ls -l "${file}" | ${arcAwkProg} '{print $5 }' | tail -1)
   if ! num_is_num "${bytes}"; then
      _fileThrowError "Bytes is not a number: ${bytes}: $*: file_get_size"
      echo 0
   else
      echo ${bytes}
   fi
}

function test_file_get_size {
   file_get_size "${arcHome}/arcshell_setup.sh" | assert ">0" "File size should be greater than zero."
   file_get_size 2>&1 >/dev/null | assert_match "ERROR"
   file_get_size "/does_not_exist" 2>&1 >/dev/null | assert_match "ERROR"
}

function file_get_file_count {
   # Return the number of files from defined or current directory.
   # >>> file_get_file_count "directory"
   ${arcRequireBoundVariables}
   typeset directory fileCount file_name
   directory=${1:-}
   if [[ -z "${directory}" ]]; then
      directory="$(pwd)"
   fi
   fileCount=0
   while read file_name; do
      [[ -f "${directory}/${file_name}" ]] && ((fileCount=fileCount+1))
   done < <(ls "${directory}")
   echo ${fileCount}
}

function test_file_get_file_count {
   rm -rf "/tmp/x" 2> /dev/null
   mkdir -p "/tmp/x"
   mkdir -p "/tmp/x/c"
   touch "/tmp/x/a"
   touch "/tmp/x/b"
   file_get_file_count "/tmp/x" | assert 2
   cd "/tmp/x"
   file_get_file_count | assert 2
   cd "/tmp"
   rm -rf "/tmp/x"
}

function file_is_empty {
   # Return true if file is zero bytes or contains only blank lines.
   # >>> file_is_empty "file"
   ${arcRequireBoundVariables}
   typeset file_name x
   file_name="${1}"
   cd $(pwd)
   if ! [[ -s "${file_name}" ]] || (( $(egrep -v "^ *$|^$" "${file_name}" | wc -l) == 0 )); then
      ${returnTrue}
   else 
      ${returnFalse}
   fi
}

function test_file_is_empty {
   [[ -f "/tmp/empty_file" ]] && rm "/tmp/empty_file"
   touch "/tmp/empty_file"
   file_is_empty "/tmp/empty_file" && pass_test || fail_test
   echo "foo" >> "/tmp/empty_file"
   ! file_is_empty "/tmp/empty_file" && pass_test || fail_test
   rm "/tmp/empty_file"
}

function file_exists {
   # Return true if file exists.
   # >>> file_exists "file"
   ${arcRequireBoundVariables}
   typeset file
   file="${1}"
   [[ -f "${file}" ]] && ${returnTrue} || ${returnFalse}
}

function test_file_exists {
   file_exists /etc/passwd && pass_test || fail_test
   file_exists /etc/does_not_exist && fail_test || pass_test
}


function _fileThrowError {
   # Generic error handler for this module.
   # >>> _fileThrowError "errorText"
   throw_error "arcshell_file.sh" "${1}"
}

function test__fileThrowError {
   pass_test
}





