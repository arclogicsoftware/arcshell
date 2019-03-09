# module_flle="arcshell_compiler.sh"
# module_name="Compiler"
# module_about="Transforms modules with multiple dependencies into single executable files."
# module_version=1
# copyright_notice="Copyright 2019 Arclogic Software"

# The file which contains all of the function maps is called 
_compiler_gDir="${arcTmpDir}/_arcshell_compiler"
mkdir -p "${_compiler_gDir}"
_g_compilerGroup=
# Compile File Options
_g_compilerStarted=0
_g_compilerIncludeDebug=0
_g_compilerIncludeTests=0
_g_compilerLogFile="${arcLogDir}/compiler.log"
_g_compilerWorkfile="${_compiler_gDir}/workFile.$$"

function __setupArcShellCompiler {
   objects_register_object_model "compiler_group" "_compilerGroupDef" 
}

function test_file_setup {
   __setupArcShellCompiler
}

function _compilerGroupDef {
   # Return the compiler model for a group.
   # >>> _compilerGroupDef
   cat <<EOF
_compiler_group="${_compiler_group:-}"
EOF
}

function compiler_start {
   # Starts a new compiler session.
   # >>> compiler_start "group"
   # group: File group name.
   ${arcRequireBoundVariables}
   debug2 "compiler_start: $*"
   compiler_stop
   utl_raise_invalid_option "compiler_start" "(( $# == 1 ))" "$*"
   _compilerRaiseGroupNotFound "${1}" && ${returnFalse} 
   compiler_set_group "${1}"
   cp /dev/null "${_g_compilerWorkfile}"
   _g_compilerStarted=1
}

function compiler_stop {
   # Terminates the current compiler session.
   # >>> compiler_stop
   cp /dev/null "${_g_compilerWorkfile}"
   _g_compilerIncludeDebug=0
   _g_compilerIncludeTests=0
   _g_compilerStarted=0
}

function compiler_include {
   # Input here is appended to the header of the compiled files.
   # >>> compiler_include [-stdin | "file"]
   ${arcRequireBoundVariables}
   debug2 "compiler_include: $*"
   _compilerRaiseNotStarted && ${returnFalse} 
   if [[ "${1:-}" == "-stdin" ]]; then
      cat >> "${_g_compilerWorkfile}"
   else
      cat "${1}" >> "${_g_compilerWorkfile}"
   fi
   echo "" >> "${_g_compilerWorkfile}"
}

function test_compiler_include {
   :
}

function compiler_compile {
   # Compile the currently set file.
   # >>> compiler_compile [-debug] [-tests] "source_file" "target_file"
   # -debug: Include debug calls.
    # -tests: Include test functions.
    # source_file:
    # target_file:
   ${arcRequireBoundVariables}
   debug2 "compiler_compile: $*"
   typeset source_file target_file tmpFile
   _compilerRaiseNotStarted && ${returnFalse} 
   _g_compilerIncludeDebug=0
   _g_compilerIncludeTests=0
   while (( $# > 0)); do
      case "${1}" in
         "-debug") _g_compilerIncludeDebug=1 ;;
         "-tests") _g_compilerIncludeTests=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "compiler_compile" "(( $# == 2 ))" "$*"
   source_file="${1}"
   file_raise_file_not_found "${source_file}" && ${returnFalse} 
   target_file="${2}"
   if [[ "${source_file}" -ef "${target_file}" ]]; then
      _compilerThrowError "Source file and output file are the same: $*: compiler_compile"
      ${returnFalse} 
   fi
   tmpFile="$(mktempf)"
   cp "${_g_compilerWorkfile}" "${tmpFile}"
   # Dependencies should load first.
   _compilerGetDependencies "${source_file}" "unittest.sh|debug.sh" >> "${tmpFile}"
    compiler_banner "$(basename "${source_file}")" >> "${tmpFile}"
   cat "${source_file}" >> "${tmpFile}"
   if (( ${_g_compilerIncludeDebug} == 0 )); then
      _compilerFilterRemoveDebug "${tmpFile}" > "${tmpFile}~"
      mv "${tmpFile}~" "${tmpFile}"
   fi
   if (( ${_g_compilerIncludeTests} == 0 )); then
      _compilerFilterRemoveTests "${tmpFile}" > "${tmpFile}~"
      mv "${tmpFile}~" "${tmpFile}"
   fi
   _compilerFilterRemoveDoubleUnderscoreFunctions "${tmpFile}" > "${tmpFile}~"
   mv "${tmpFile}~" "${target_file}"
   chmod 700 "${target_file}"
   ${returnTrue} 
}

function _compilerRaiseNotStarted {
   if [[ -z "${_g_compilerStarted:-}" ]]; then
      _compilerThrowError "Compiler file not started: $*: _compilerRaiseNotStarted"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function compiler_create_group {
   # Create a compiler file group.
   # >>> compiler_create_group "group"
   # group: Name of group. Must be a ```key string```.
   ${arcRequireBoundVariables}
   #debug2 "$*: compiler_create_group"
   typeset group 
   group="${1}"
   str_raise_not_a_key_str "compiler_create_group" "${group}" && ${returnFalse} 
   eval "$(objects_init_object "compiler_group")"
   _compiler_group="${group}"
   objects_save_object "compiler_group" "${group}" 
   mkdir -p "${_compiler_gDir}/${group}"
   compiler_set_group "${group}"
   ${returnTrue} 
}

function test_compiler_create_group {
   compiler_delete_group "foo" && pass_test || fail_test 
   ! compiler_does_group_exist "foo" && pass_test || fail_test 
   compiler_create_group "foo" && pass_test || fail_test 
   compiler_does_group_exist "foo" && pass_test || fail_test 
}

function compiler_define_group {
   # Associates the group with a list of files.
   # >>> compiler_define_group [-stdin | "file"]
   # file: A file containing a list of files which define the group.
   ${arcRequireBoundVariables}
   typeset f
   #debug2 "compiler_define_group: $*"
   _compilerRaiseGroupNotSet && ${returnFalse} 
   mkdir -p "${_compiler_gDir}/${_g_compilerGroup}"
   f="${_compiler_gDir}/${_g_compilerGroup}/${_g_compilerGroup}.files"
   if [[ "${1}" == "-stdin" ]]; then
      cat > "${f}"
   else
      cat "${1}" | compiler_define_group -stdin
   fi
   ${returnTrue} 
}

function test_compiler_define_group {
   find "${arcHome}/sh/core" -type f | egrep "arcshell_cache.sh|arcshell_str.sh" | compiler_define_group -stdin "foo"
   _compilerListFiles "foo" | assert -l 2
}

function compiler_generate_resources {
   # Generate maps and requirements which are needed to compile libraries.
   # >>> compiler_generate_resources ["regex"]
   ${arcRequireBoundVariables}
   #debug2 "compiler_generate_resources: $*"
   typeset regex 
   _compilerRaiseGroupNotSet && ${returnFalse} 
   if (( $# == 1 )); then
      regex="${1}"
   fi
   _compilerGenerateMaps "${regex:-}" || ${returnFalse} 
   _compilerGenerateRequirements "${regex:-}" || ${returnFalse} 
   ${returnTrue} 
}

function test_compiler_generate_resources {
   compiler_generate_resources && pass_test || fail_test 
}

function _compilerGenerateMaps {
   # This function sets up the loop so that each file in the compiler group is mapped against every other file within the group.
   # >>> _compilerGenerateMaps ["regex"]
   # regex: Rebuild the call maps for files matching ```regex```.
   ${arcRequireBoundVariables}
   #debug2 "_compilerGenerateMaps: $*"
   typeset map_from_file map_to_file regex 
   _compilerRaiseGroupNotSet && ${returnFalse}
   regex=".*"
   find "${_compiler_gDir}/${_g_compilerGroup}" -type f -name "*.funcs~" -exec rm {} \;
   if [[ -z "${1:-}" ]]; then
      # All files in the group are going to be processed so we can truncate the .maps file.
      cp /dev/null "${_compiler_gDir}/${_g_compilerGroup}/${_g_compilerGroup}.maps"
      regex=".*"
   else
      # We are not processing all of the files. Don't zero out the .maps file. References will need to be removed for each file being processed.
      regex="${1}"
      touch "${_compiler_gDir}/${_g_compilerGroup}/${_g_compilerGroup}.maps"
   fi
   while read map_from_file; do
      debug0 "$(printf "\n-- Mapping %s --\n" "${map_from_file}")"
      while read map_to_file; do
         _compilerMapFilePair "${map_from_file}" "${map_to_file}"
      done < <(_compilerListFiles)
   done < <(_compilerListFiles | egrep "${regex}")
   ${returnTrue} 
}

function test__compilerGenerateMaps {
   _compilerGenerateMaps && pass_test || fail_test 
}

function _compilerMapFilePair {
   # Checks 'map_from_file' to see if calls are being made to 'map_to_file'.
   # >>> _compilerMapFilePair "map_from_file" "map_to_file" 
   ${arcRequireBoundVariables}
   #debug1 "_compilerMapFilePair: $*"
   typeset tmpFile line_from_tmp_file map_from_file map_to_file possible_function map_to_file_function_list
   _compilerRaiseGroupNotSet && ${returnFalse} 
   map_from_file="${1}"
   map_to_file="${2}"
   tmpFile="$(mktempf "${_g_compilerGroup}")" 
   _compilerDeleteMap "${map_from_file}" "${map_to_file}"
   debug0 "$(printf "\nMapping %s\n" "["$(basename "${map_from_file}")"] -> ["$(basename "${map_to_file}")"]")"
   map_to_file_function_list="$(_compilerGetFunctionListBuildIfMissing "${map_to_file}")"
   #debug3 "map_to_file_function_list=${map_to_file_function_list}" 
   _compilerFilterRemoveDebug "${map_from_file}" | _compilerFilterRemoveFunction -stdin "^test_|^__" | \
      egrep "${map_to_file_function_list}|^function |[A-Z|a-z].* \(\).*{" | \
      str_remove_comments -stdin | tr '][=&*",()|<>{};:$-' ' ' > "${tmpFile}"
   #cat "${tmpFile}" | debugd3
   (
   while read line_from_tmp_file; do
      if [[ "${line_from_tmp_file:0:8}" == "function" ]]; then
         last_function="$(echo "${line_from_tmp_file:-}" | awk '{print $2}')"
      else
         while read possible_function; do 
            #debug0 "Possible function = ${possible_function}"
            [[ -z "${last_function:-}" ]] && last_function="ERROR_NOT_SET"
            if [[ "${possible_function}" != "${last_function}" ]] && \
               [[ "${last_function:0:2}" != "__" ]] && \
               grep "^function ${possible_function} " "${map_to_file}" 1> /dev/null; then
               debug0 "$(printf "%-40s -> %-40s\n" "${last_function}" "${possible_function}")"
               printf "%s:%s:%s:%s\n" "${map_to_file}" "${possible_function}" "${map_from_file}" "${last_function}"
            fi
         done < <(echo "${line_from_tmp_file}" | str_split_line -stdin " " | egrep "${map_to_file_function_list}" | sort | uniq)
      fi
   done < "${tmpFile}"
   ) | sort | uniq >> "${_compiler_gDir}/${_g_compilerGroup}/${_g_compilerGroup}.maps"
   rmtempf "${_g_compilerGroup}"
   ${returnTrue} 
}

function test__compilerMapFilePair {
   _compilerMapFilePair "${arcHome}/sh/core/arcshell_cache.sh" "${arcHome}/sh/core/arcshell_str.sh" && pass_test || fail_test 
}

function _compilerGenerateRequirements {
   # Generates one or more ```.reqs``` requirements files. These files contain the list of functions which need to be loaded to compile a single library,
   # >>> _compilerGenerateRequirements ["regex"]
   typeset main_file regex 
   regex=".*"
   (( $# == 1 )) && regex="${1}"
   _compilerRaiseGroupNotSet && ${returnFalse} 
   while read main_file; do
      _compilerGenerateRequirementsForFile "${main_file}"
   done < <(_compilerListFiles "${_g_compilerGroup}" | egrep "${regex}")
   ${returnTrue} 
}

function test__compilerGenerateRequirements {
   _compilerGenerateRequirements && pass_test || fail_test 
}

function _compilerGenerateRequirementsForFile {
   # Generate the ```.reqs``` file for a library.
   # >>> _compilerGenerateRequirementsForFile "main_file"
   ${arcRequireBoundVariables}
   typeset main_file func file_root_name
   _compilerRaiseGroupNotSet && ${returnFalse} 
   main_file="${1}"
   file_root_name="$(file_get_file_root_name "${main_file}")"
   cp /dev/null "${_g_compilerWorkfile}" 
   while read func; do
      _compilerGenerateRequirementsForFunction "${main_file}" "${func}" 0
   done < <(_compilerListRegularFunctions "${main_file}"; _compilerListTestFunctions "${main_file}")
   cat "${_g_compilerWorkfile}" | awk -F":" '{print $1" "$2}' | \
      egrep -v "^${main_file}" | str_uniq -stdin > "${_compiler_gDir}/${_g_compilerGroup}/${file_root_name}.reqs"
   rm "${_g_compilerWorkfile}"
}

function test__compilerGenerateRequirementsForFile {
   _compilerGenerateRequirementsForFile "${arcHome}/sh/core/arcshell_cache.sh" && pass_test || fail_test 
}

function _compilerGenerateRequirementsForFunction {
   # This recursive function maps the complete chain of dependencies for a function.
   # >>> _compilerGenerateRequirementsForFunction "main_file" "func" [map_depth]
   typeset d main_file map_func s f map_depth
   debug2 "_compilerGenerateRequirementsForFunction: $*"
   [[ -z "${_g_compilerGroup}" ]] && ${returnFalse} 
   main_file="${1}"
   map_func="${2}"
   map_depth=${3:-0}
   if (( ${map_depth} > 20 )); then
      _compilerThrowError "Max depth exceeded: $*: _compilerGenerateRequirementsForFunction" 
      ${returnFalse} 
   fi
   ((map_depth=map_depth+1))
   while read d; do
      s="$(echo "${d}" | cut -d":" -f1)"
      f="$(echo "${d}" | cut -d":" -f2)"
      if ! grep "${d}" "${_g_compilerWorkfile}"  1> /dev/null; then
         echo "${d}:${map_depth}" >> "${_g_compilerWorkfile}" 
         _compilerGenerateRequirementsForFunction "${s}" "${f}" ${map_depth}
      fi
   done < <(egrep ":${main_file}:${map_func}$" "${_compiler_gDir}/${_g_compilerGroup}/${_g_compilerGroup}.maps")
}

function test__compilerGenerateRequirementsForFunction {
   :
}

function _compilerListFiles {
   # Return the list of files associated with current group.
   # >>> _compilerListFiles ["group"]
   ${arcRequireBoundVariables}
   typeset file 
   if [[ -n "${1:-}" ]]; then
      compiler_set_group "${1}" || ${returnFalse} 
   fi
   _compilerRaiseGroupNotSet && ${returnFalse} 
   file="${_compiler_gDir}/${_g_compilerGroup}/${_g_compilerGroup}.files"
   cat "${file}"
   ${returnTrue} 
}

function test__compilerListFiles {
   _compilerListFiles | assert -l 2
}

function _compilerRaiseGroupNotFound {
   # Raise error and return true if compiler group is not found.
   # >>> _compilerRaiseGroupNotFound "group"
   ${arcRequireBoundVariables}
   typeset group 
   group="${1}"
   if ! objects_does_temporary_object_exist "compiler_group" "${group}"; then
      _compilerThrowError "Compiler group not found: $*: _compilerRaiseGroupNotFound"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test__compilerRaiseGroupNotFound {
   _compilerRaiseGroupNotFound "fooX" && pass_test || fail_test 
   ! _compilerRaiseGroupNotFound "foo" && pass_test || fail_test 
}

function compiler_delete_group {
   # Delete a compiler file group and all associated resources.
   # >>> compiler_delete_group ["group"]
   ${arcRequireBoundVariables}
   utl_raise_invalid_option "compiler_delete_group" "(( $# <= 9 ))" ["$*"] 
   if [[ -n "${1:-}" ]]; then
      compiler_set_group "${1}" || ${returnFalse} 
   fi
   _compilerRaiseGroupNotSet && ${returnFalse} 
   objects_delete_temporary_object "compiler_group" "${_g_compilerGroup}"
   rm -rf "${_compiler_gDir}/${_g_compilerGroup}"
   compiler_unset
   ${returnTrue} 
}

function test_compiler_delete_group {
   compiler_does_group_exist "foo" && pass_test || fail_test 
   compiler_delete_group "foo" && pass_test || fail_test 
   ! compiler_does_group_exist "foo" && pass_test || fail_test 
}

function compiler_does_group_exist {
   # Return true if compiler fil egroup exists.
   # >>> compiler_does_group_exist "group"
   ${arcRequireBoundVariables}
   typeset group 
   group="${1}"
   if objects_does_temporary_object_exist "compiler_group" "${group}"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test_compiler_does_group_exist {
   # Already tested.
   :
}

function compiler_set_group {
   # Set the global file group variable to the defined value.
   # >>> compiler_set_group "group"
   ${arcRequireBoundVariables}
   #debug2 "compiler_set_group: $*"
   typeset group 
   group="${1}"
   _compilerRaiseGroupNotFound "${group}" && ${returnFalse} 
   _g_compilerGroup="${group}"
   ${returnTrue} 
}

function test_compiler_set_group {
   :
}

function compiler_unset {
   # Unset the global file group variable.
   # >>> compiler_unset
   _g_compilerGroup=
   ${returnTrue} 
}

function test_compiler_unset {
   :
}

function _compilerRaiseGroupNotSet {
   # Raise error and return true if global group variable is not set.
   # >>> _compilerRaiseGroupNotSet
   if [[ -z "${_g_compilerGroup:-}" ]]; then
      _compilerThrowError "Compiler group is not set: $*: _compilerRaiseGroupNotSet"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test__compilerRaiseGroupNotSet {
   ! _compilerRaiseGroupNotSet && pass_test || fail_test 
   compiler_unset 
   _compilerRaiseGroupNotSet && pass_test || fail_test 
}

function _compilerDeleteMap {
   # Deletes the call map for records where ```file1``` calls functions from ```file2```.
   # >>> _compilerDeleteMap "file1" "file2"
   typeset main_file calls_file 
   main_file="${1}"
   calls_file="${2}"
   [[ -z "${_g_compilerGroup}" ]] && ${returnFalse} 
   sed '/^${calls_file}:.*:${main_file}:.*/d' "${_compiler_gDir}/${_g_compilerGroup}/${_g_compilerGroup}.maps" > "${tmpFile}"
   mv "${tmpFile}" "${_compiler_gDir}/${_g_compilerGroup}/${_g_compilerGroup}.maps"
   ${returnTrue} 
}

function test__compilerDeleteMap {
   :
}

function _compilerGetFunctionListBuildIfMissing {
   # Return the piped delimited list of functions from a file. This string can be used with egrep.
   # >>> _compilerGetFunctionListBuildIfMissing "file"
   ${arcRequireBoundVariables}
   typeset file b 
   _compilerRaiseGroupNotSet && ${returnFalse} 
   file="${1}"
   b="$(basename "${file}").funcs~"
   if ! [[ -f "${_compiler_gDir}/${_g_compilerGroup}/${b}" ]]; then
      _compilerGetCompilableFunctions "${file}" > "${_compiler_gDir}/${_g_compilerGroup}/${b}"
   fi
   cat "${_compiler_gDir}/${_g_compilerGroup}/${b}"
}

function _compilerGetHeader {
   #
   # >>> _compilerGetHeader "file"
   ${arcRequireBoundVariables}
   typeset file 
   _compilerRaiseGroupNotSet && ${returnFalse} 
   file="${1}"
   _compilerFilterRemoveFunction "${file}" ".*" 
}

function _compilerGetCompilableFunctions {
   # List functions which are able to be considered when calculating dependencies.
   # >>> _compilerGetCompilableFunctions "file"
   ${arcRequireBoundVariables}
   typeset file 
   file="${1}"
   debug3 "_compilerGetCompilableFunctions: $*"
   boot_list_functions "${file}" | egrep -v "^__|^test_" | _compilerToPipeSeparatedList | str_trim_line -stdin
}

function _compilerToPipeSeparatedList {
   # Return values in pipe separated format.
   # >>> _compilerToPipeSeparatedList [-stdin]
   str_to_csv "|"
}

function _compilerGetDependencies {
   # Return the function dependencies for a file.
   # >>> _compilerGetDependencies "file" ["regex"]
   # regex: This regular expression is used to prevent loading dependencies from matching libraries.
   ${arcRequireBoundVariables}
   debug2 "_compilerGetDependencies: $*"
   typeset file req_file regex func x tmpFile
   _compilerRaiseGroupNotSet && ${returnFalse} 
   file="${1}"
   regex="${2:-"NullExclude"}"
   file_raise_file_not_found "${file}" && ${returnFalse} 
   file_root_name="$(file_get_file_root_name "${file}")"
   req_file="${_compiler_gDir}/${_g_compilerGroup}/${file_root_name}.reqs"
   file_raise_file_not_found "${req_file}" && ${returnFalse} 
   tmpFile="$(mktempf)"
   cat "${req_file}" | sort | egrep -v "${regex}" | awk -F" " '{print $1}' | sort | uniq > "${tmpFile}"
   compiler_banner "$(basename "${file}") Dependent Headers"
   while read x; do
      echo ""
      _compilerGetHeader "${x}" | utl_remove_blank_lines -stdin
      echo ""
   done < "${tmpFile}"
   rm "${tmpFile}"
   compiler_banner "$(basename "${file}") Dependent Functions"
   while read x; do
      IFS=' ' read file func <<< "${x}"
      echo ""
      utl_get_function_def "${file}" "${func}"
      echo ""
   done < <(cat "${req_file}" | sort | egrep -v "${regex}")   
}

function _compilerListRegularFunctions {
   # Lists functions. Excludes special double underscore functions and test functions.
   # >>> _compilerListRegularFunctions "file"
   ${arcRequireBoundVariables}
   typeset file 
   file="${1}"
   boot_list_functions "${file}" | egrep -v "^__|^test_"
}

function _compilerListTestFunctions {
   # List regular test functions. Excludes special setup and teardown functions.
   # >>> _compilerListTestFunctions "file"
   ${arcRequireBoundVariables}
   typeset file 
   file="${1}"
   boot_list_functions "${file}" | egrep "^test_" | egrep -v "test_file_setup|test_function_setup|test_file_teardown|test_function_teardown"
}

function _compilerFilterRemoveFunction {
   # Modifies ```stdin``` by removing one or more functions matching ```regex``` and returns to ```stdout```.
   # >>> _compilerFilterRemoveFunction [-stub,-s] [-stdin | "file"] "regex"
   ${arcRequireBoundVariables}
   typeset regex stub stdin file
   debug3 "_compilerFilterRemoveFunction: $*"
   stub=0
   stdin=0
   while (( $# > 0)); do
      case "${1}" in
         "-stub"|"-s") stub=1 ;; 
         "-stdin") stdin=1     ;;     
         *) break              ;;
      esac
      shift
   done
   utl_raise_invalid_option "_compilerFilterRemoveFunction" "(( $# <= 2 ))" "$*"
   if (( $# == 2 )); then
      file="${1}"
      shift 
   fi 
   regex="${1}"
   if (( ${stdin} )); then
      awk -v stub=${stub} -v regex="${regex}" -f "${arcHome}/sh/core/_compilerRemoveFunction.awk" 
   else
      awk -v stub=${stub} -v regex="${regex}" -f "${arcHome}/sh/core/_compilerRemoveFunction.awk" "${file}"
      shift
   fi
}

function _compilerRemoveFunction {
   # Returns file contents but removes a single function.
   # >>> _compilerRemoveFunction "file" "func"
   ${arcRequireBoundVariables}
   typeset file func start lines x i end
   file="${1}"
   func="${2}"
   start=$(grep -n "^function ${func} " "${file}" | cut -d":" -f1)
   end=0
   lines=$(wc -l "${file}" | cut -d" " -f1)
   i=0
   if [[ -n "${start}" && -n "${lines}" ]]; then   
      while IFS= read -r x; do
         ((i=i+1))
         if [[ "${x:0:1}" == "}" ]]; then
            break
         fi
      done < <(sed -n "${start},${lines}p" "${file}")
      ((end=start+i-1))
      sed "${start},${end}d" "${file}"
   else
      cat "${file}"
   fi
}

function _compilerFilterRemoveDebug {
   # Remove debug calls from the stream.
   # >>> _compilerFilterRemoveDebug [-stdin | "file"]
   ${arcRequireBoundVariables}
   if [[ "${1}" == "-stdin" ]]; then
      cat | awk -f "${arcHome}/sh/core/_remove_debug.awk" 
   else
      awk -f "${arcHome}/sh/core/_remove_debug.awk" "${1}"
   fi   
}

function _compilerFilterRemoveTests {
   # 
   # >>> _compilerFilterRemoveTests [-stdin | "file"]
   ${arcRequireBoundVariables}
   if [[ "${1}" == "-stdin" ]]; then
      cat | _compilerFilterRemoveFunction -stdin "^test_.*"
   else
      cat "${1}" | _compilerFilterRemoveFunction -stdin "^test_.*" 
   fi
   ${returnTrue} 
}

function _compilerFilterRemoveDoubleUnderscoreFunctions {
   # 
   # >>> _compilerFilterRemoveDoubleUnderscoreFunctions [-stdin | "file"]
   ${arcRequireBoundVariables}
   if [[ "${1}" == "-stdin" ]]; then
      cat | _compilerFilterRemoveFunction -stdin "^__.*"
   else
      cat "${1}" | _compilerFilterRemoveFunction -stdin "^__.*" 
   fi
   ${returnTrue} 
}

function compiler_banner {
   # Returns a simple banner/break.
   # >>> compiler_banner "str"
   # str: Any string.
   cat <<EOF

# -------------------------------------------------------------------------------
# ${1}
# -------------------------------------------------------------------------------

EOF
}

function _compilerLogfileContent {
   # Writes the contents of a file to a log before making changes to the original file.
   # >>> _compilerLogfileContent "file"
   ${arcRequireBoundVariables}
   typeset file 
   file="${1}"
   file_raise_file_not_found "${file}" && ${returnFalse} 
   (
   cat <<EOF
-------------------------------------------------------------------------------
${file}
$(date)
-------------------------------------------------------------------------------
$(cat "${file}")

EOF
   ) >> "${_g_compilerLogFile}"
}

function _compilerThrowError {
   throw_error "arcshell_compiler.sh" "${1:-}"
}


# rm "${_compiler_gDir}/maps/"* 2> /dev/null
# #source_file="${arcHome}/sh/core/arcshell_cache.sh"
# #_compiler_create_call_map 
# __compilerGenerateRequirementsForFile_arcshell


# Note, the compiler does not deal with tests in files other then the source.
