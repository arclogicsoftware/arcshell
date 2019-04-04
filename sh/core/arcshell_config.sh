
# module_name="Configuration"
# module_about="Manage configuration files."
# module_version=1
# module_image="switch-4.png"
# copyright_notice="Copyright 2019 Arclogic Software"

mkdir -p "${arcHome}/config"
mkdir -p "${arcGlobalHome}/config"
mkdir -p "${arcUserHome}/config"

_g_configConfigFile=
_g_configWorkFile=
_g_configIsDirty=0

function __readmeConfig {
   cat <<EOF
> I'm not a great programmer; I'm just a good programmer with great habits. -- Kent Beck

# Configuration

**Manage configuration files.**

This module can be used to interact with a configuration files and ArcShell configuration objects.

The \`\`\`config_merge\`\`\` function is used to merge settings assigned in "old_file" to "new_file" without disturbing any other lines or values in "new_file". This function can't merge variable values that span more than one line.

The  \`\`\`config_file_*\`\`\` functions are a bit more sophisticated in that they do work with variable values that span multiple lines. The process of of assigning values is under the control of the programmer.

Finally the other \`\`\`config_*\`\`\` functions are meant to interact specifically with ArcShell configuration objects.

These objects are stored in one or more of the \`\`\`config\`\`\` folders for each of the three ArcShell homes.

\`\`\`
\${arcHome}/config
\${arcGlobalHome}/config
\${arcUserHome}/config
\`\`\`
Depending on the design implemented the module may load the first configuration file found or it may all of the configuration files. This can be accomplished in a top-down order, or bottom up.

ArcShell configuration files are often simply shell scripts containing variable assignments. As such you are free to use valid shell commands to determine the settings of these assignments.

EOF
}

function test_file_setup {
      (
   cat <<EOF
# Foo 
foo="x"

# Bar
bar=1

# Multi-line variable.
m="Arclogic

Software"

EOF
   ) > /tmp/foo.cfg

   mkdir "${arcHome}/config/foo"
   (
   cat <<EOF
   test_value=1
EOF
   ) > "${arcHome}/config/foo/foo"
   (
   cat <<EOF
   test_value=0
EOF
   ) > "${arcHome}/config/foo/bar"

}

function __setupArcShellConfig {
   _configPropogateTypesOfObjects
}

function config_merge {
   # Updates new_file by merging assignments from old_file where there are common variables.
   # >>> config_merge "new_file" "old_file"
   # new_file: Any file containing "parameter=value" assignments.
   # old_file: The configuration file to use existing values from.
   typeset new_file old_file new_line var tmpFile
   new_file="${1}"   
   old_file="${2}"
   tmpFile="$(mktempf "mergeConfigFiles")"
   (
   while IFS= read -r new_line; do
      if [[ "${new_line:-}" =~ ^[A-Z|a-z]*= ]]; then
         var="$(echo ${new_line} | cut -d"=" -f1)"
         if grep "^${var}=" "${old_file}" 1> /dev/null; then
            # Instead of returning the new line, we will return the old line.
            grep "^${var}=" "${old_file}" 
         else
            echo "${new_line}"
         fi
      else
         echo "${new_line}"
      fi
   done < "${new_file}"
   ) > "${tmpFile}"
   if (( $(diff "${old_file}" "${tmpFile}" | wc -l) > 0 )); then
      debug0 "** Merged Configuration File ** '${old_file}'"
      diff "${old_file}" "${tmpFile}" | debugd0
      cp "${old_file}" "${arcTmpDir}/$(basename ${old_file}).$(dt_ymd_hms)"
      cp "${tmpFile}" "${old_file}"
   fi
   rm "${old_file}"
   rmtempf "mergeConfigFiles"
}

function config_file_set {
   # Loads the configuration we want to work with from a file.
   # >>> config_file_set "file"
   ${arcRequireBoundVariables}
   configFile="${1}"
   file_raise_file_not_found "${configFile}" && ${returnFalse} 
   _configRaiseConfigFileAlreadySet && ${returnFalse} 
   _configRaiseConfigIsDirty && ${returnFalse} 
   _g_configWorkFile="$(mktempf "configWorkingFile")"
   cp "${configFile}" "${_g_configWorkFile}"
   utl_add_missing_newline_to_end_of_file "${_g_configWorkFile}"
   _g_configConfigFile="${configFile}"
   ${returnTrue}
}

function test_config_file_set {
   config_file_cancel
   ! _configIsConfigSet && pass_test || fail_test "Config should not be set."
   config_file_set "/tmp/foo.cfg"
   _configIsConfigSet && pass_test || fail_test "Config should be set."
}

function _configRaiseParameterNotFound {
   # Throw error and returns true if named parameter is not found in file.
   # >>> _configRaiseParameterNotFound "file" "parameter"
   ${arcRequireBoundVariables}
   typeset file parameter
   file="${1}"
   parameter="${2}"
   if _configDoesParameterExist "${file}" "${parameter}"; then
      ${returnFalse} 
   else
      _configThrowError "Parameter not found: $*: _configRaiseParameterNotFound"
      ${returnTrue}
   fi
}

function test__configRaiseParameterNotFound {
   _configRaiseParameterNotFound "${_g_configWorkFile}" "user" 2>&1 | assert_match "ERROR" "Invalid parm should throw an error."
   _configRaiseParameterNotFound "${_g_configWorkFile}" "user" 2> /dev/null && pass_test || fail_test "Invalid parm should return true."
   _configRaiseParameterNotFound "${_g_configWorkFile}" "foo" 2>&1 | assert -l 0 "Valid parm should not raise error or return output."
   ! _configRaiseParameterNotFound "${_g_configWorkFile}" "foo" 2> /dev/null && pass_test || fail_test "Valid parm should return false."
}

function _configRaiseConfigFileNotSet {
   # Throw error and return true if config file has not been set.
   # >>> _configRaiseConfigFileNotSet
   ${arcRequireBoundVariables}
   if [[ -f "${_g_configConfigFile}" ]]; then
      ${returnFalse}
   else
      _configThrowError "Config file is not set: _configRaiseConfigFileNotSet "
      ${returnTrue}
   fi
}

function test__configRaiseConfigFileNotSet {
   _configRaiseConfigFileNotSet 2>&1 | assert -l 0 "Was not expecting output, config should be set."
   ! _configRaiseConfigFileNotSet 2> /dev/null && pass_test || fail_test "Why didn't we return false, config should be set."
   config_file_cancel
   _configRaiseConfigFileNotSet 2>&1 | assert_match "ERROR" "Expected ERROR since config is not set."
   _configRaiseConfigFileNotSet 2> /dev/null && pass_test || fail_test "Expected True since config is not set."
}

function _configRaiseConfigFileAlreadySet {
   # Raise error and return true if config file has already been set.
   # >>> _configRaiseConfigFileNotSet
   ${arcRequireBoundVariables}
   if [[ -f "${_g_configConfigFile}" ]]; then
      _configThrowError "Config file is already set: _configRaiseConfigFileNotSet "
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test__configRaiseConfigFileAlreadySet {
   _configRaiseConfigFileAlreadySet 2>&1 | assert -l 0 "Didn't expect any output, config should not be set."
   ! _configRaiseConfigFileAlreadySet 2> /dev/null && pass_test || fail_test "Expected false return value."
   config_file_set "/tmp/foo.cfg"
   _configRaiseConfigFileAlreadySet 2>&1 | assert_match "ERROR" "Expected ERROR, config file should be set."
   _configRaiseConfigFileAlreadySet 2> /dev/null && pass_test || fail_test "Expected true return value."
}

function _configRaiseConfigIsDirty {
   # Raise error and return true if config is dirty.
   # >>> _configRaiseConfigIsDirty
   ${arcRequireBoundVariables}
   if (( ${_g_configIsDirty} )); then
      _configThrowError "Config is dirty: $*: _configRaiseConfigIsDirty"
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test__configRaiseConfigIsDirty {
   :
}

function config_file_set_parm {
   # Sets an existing parameter value in the working copy of the config file..
   # >>> config_file_set_parm "parameter" "value"
   typeset parameter value untilLine fromLine
   debug3 "config_file_set_parm: $*"
   parameter="${1}"
   value="${2}"
   if _configRaiseConfigFileNotSet && \
      _configDoesParameterExist "${_g_configWorkFile}" "${parameter}"; then
      l=$(_configReturnParameterLineNum "${_g_configWorkFile}" "${parameter}")
      if (( ${l} )); then
         ((untilLine=l-1))
         l=$(_configReturnEndOfParameterLineNum "${_g_configWorkFile}" "${parameter}" "${l}")
         if (( ${l} )); then
            ((fromLine=l+1))
            (
            sed -n "1,${untilLine}"p "${_g_configWorkFile}"
            if num_is_num "${value}"; then
               echo "${parameter}=${value}"
            else
               echo "${parameter}=\"${value}\""
            fi
            sed -n "${fromLine},$"p "${_g_configWorkFile}"
            ) > "${_g_configWorkFile}.tmp"
            mv "${_g_configWorkFile}.tmp" "${_g_configWorkFile}"
            _g_configIsDirty=1
         fi
      else
          _configThrowError "Parameter line should be greater than 0: ${l}: config_file_set_parm"
      fi
   fi
}

function test_config_file_set_parm {
   :
}

function _configReturnParameterLineNum {
   # Returns parameter line number from the configuration file. Returns zero if not found.
   # >>> _configReturnParameterLineNum "configFile" "parameter"
   typeset configFile parameter parameterLine
   configFile="${1}"
   parameter="${2}"
   parameterLine=$(grep -n "^${parameter}=" "${configFile}" | cut -d":" -f1)
   if [[ -z "${parameterLine}" ]]; then
      parameterLine=0
   fi
   echo ${parameterLine}
}

function test__configReturnParameterLineNum {
   :
}

function _configReturnEndOfParameterLineNum {
   # Return the ending line number for a parameter value pair in a config file.
   # >>> _configReturnEndOfParameterLineNum "configFile" "parameter" startingLineNumber
   ${arcRequireBoundVariables}
   typeset configFile parameter parameterLine startLine lineCount x endLine v
   configFile="${1}"
   parameter="${2}"
   startLine=${3}
   endLine=${startLine}
   x="$(sed -n "${startLine},1p" "${configFile}")"
   v="$(echo "${x}" | cut -d"=" -f2)"
   if _configIsValueQuoted "${v}" && _configIsValueMultiline "${x}"; then
      ((startLine=startLine+1))
      lineCount=$(wc -l "${configFile}" | cut -d" " -f1)
      while read x; do
         ((endLine=endLine+1))
         if _configIsEndOfMultiline "${x}"; then
            echo ${endLine}
            break
         fi
      done < <(sed -n "${startLine}, ${lineCount}p" "${configFile}")
   else
      echo ${startLine}
   fi
}

function test__configReturnEndOfParameterLineNum {
   :
}

function _configDoesParameterExist {
   # Return true if named parameter is found in file.
   # >>> _configDoesParameterExist "file" "parameter"
   ${arcRequireBoundVariables}
   typeset file parameter
   file="${1}"
   parameter="${2}"
   if grep "^${parameter}=" "${_g_configWorkFile}" 1> /dev/null; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test__configDoesParameterExist {
   :
}

function config_file_get_parm {
   # Returns the value of a parameter from the working configuration file.
   # >>> config_file_get_parm "parameter"
   ${arcRequireBoundVariables}
   typeset parameter startLine endLine tmpFile
   parameter="${1}"
   if ! _configRaiseConfigFileNotSet && \
      ! _configRaiseParameterNotFound "${_g_configWorkFile}" "${parameter}"; then
      startLine=$(_configReturnParameterLineNum "${_g_configWorkFile}" "${parameter}")
      endLine=$(_configReturnEndOfParameterLineNum "${_g_configWorkFile}" "${parameter}" ${startLine})
      tmpFile=$(mktempf "getParameterValue")
      (
      sed -n "${startLine},${endLine}"p "${_g_configWorkFile}" 
      echo "echo \"\${${parameter}}\""
      ) > "${tmpFile}"
      chmod 700 "${tmpFile}"
      "${tmpFile}"
      rmtempf "getParameterValue"
      # grep "^${parameter}=" "${_g_configConfigFile}" | cut -d"=" -f2 | sed 's/^"//' | sed 's/"$//'
   fi
}

function test_config_file_get_parm {
   config_file_get_parm "foo" | assert "x"
   config_file_get_parm "bar" | assert 1
}

function config_file_save {
   # Saves the config by activating the working config file.
   # >>> config_file_save
   ${arcRequireBoundVariables}
   if ! _configRaiseConfigFileNotSet; then
      if (( _g_configIsDirty )); then
         cp "${_g_configWorkFile}" "${_g_configConfigFile}"
         debug2 "config_file_save: $*"
      fi
   fi
   config_file_cancel
}

# function _config_load_modifications {
#    :
# }

# function _config_copy_config {
#    # Returns the configuration file contents in a sourcable format.
#    # >>> _config_copy_config "configFile"
#    ${arcRequireBoundVariables}
#    typeset configFile var inMultilineStringValue
#    configFile="${1}"
#    inMultilineStringValue=0
#    (
#    echo ""
#    echo "cat <<EOF"
#    while IFS= read -r x; do
#       if $(_configIsParameterLine "${x}"); then
#          if ! (( ${inMultilineStringValue} )); then
#             var="$(echo ${x} | cut -d"=" -f1)"
#             varSetting="$(echo "${x}" | cut -d"=" -f2)"
#             if $(_configIsValueQuoted "${varSetting}"); then
#                if $(_configIsValueMultiline "${varSetting}"); then
#                   inMultilineStringValue=1
#                   echo "${var}=\"\${${var}:-${varSetting}"
#                else
#                   echo "${var}=\"\${${var}:-${varSetting}}\""
#                fi
#             else
#                echo "${var}=\${${var}:-${varSetting}}"
#             fi
#          else
#             _configThrowError "Can't process new parameter while reading multi-line value: $*: _config_copy_config"
#          fi
#       elif (( ${inMultilineStringValue} )) && $(_configIsEndOfMultiline "${x}"); then
#          echo "${x}}\""
#       else
#          echo "${x}"
#       fi
#    done < "${configFile}"
#    echo "EOF"
#    echo ""
#    ) > "${_g_configWorkFile}"
# }

function config_file_cancel {
   # Cancel working with the current configuration file.
   # >>> config_file_cancel
   ${arcRequireBoundVariables}
   rmtempf "configWorkingFile"
   _g_configConfigFile=
   _g_configWorkFile=
}

function test_config_file_cancel {
   config_file_cancel
   ! _configIsConfigSet && pass_test || fail_test
}

function _configIsConfigSet {
   # Return true if a configuration file has been defined.
   # >>> _configIsConfigSet
   ${arcRequireBoundVariables}
   if [[ -f "${_g_configConfigFile}" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test__configIsConfigSet {
   config_file_set "/tmp/foo.cfg"
   _configIsConfigSet && pass_test || fail_test
}

# function config_delete_parameter {
#    # Deletes a parameter from a file (not implemented).
#    # >>> config_delete 
#    ${arcRequireBoundVariables}
#    _configThrowError "Not implemented yet: $*: config_delete_parameter"
# }

# function test_config_delete_parameter {
#    :
# }

function _configIsParameterLine {
   # Return true if ```line``` appears to be assigning a value to a parameter.
   # >>> _configIsParameterLine "line"
   if [[ "${1:-}" =~ ^[A-Z|a-z|\_].*= ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function _configIsValueMultiline {
   # Return true if it appears the parameter is being assigned value spanning multiple lines.
   # >>> _configIsValueMultiline "line"
   if (( $(echo "${1:-}" | str_get_char_count -stdin '"') == 1)); then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function _configIsValueQuoted {
   # Return true if the value assigned to the parameter is quoted with double or single quote marks.
   # >>> _configIsValueQuoted "line"
   typeset s 
   s="${1:-}"
   if [[ "${s:0:1}" == '"' || "${s:0:1}" == "'" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function _configIsEndOfMultiline {
   # Return true if ```line``` appears to be the end of a parameter assignment spanning multiple lines.
   # >>> _configIsEndOfMultiline "line"
   typeset s
   s="${1:-"x"}"
   if [[ $(str_get_last_char "${s}") == '"' ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function _configThrowError {
   # Error handler for this library.
   # >>> _configThrowError "errorText"
   throw_error "arcshell_config.sh" "${1}"
}

function _configPropogateTypesOfObjects {
   # Syncs object type folder name down to global and user levels.
   # >>> _configPropogateTypesOfObjects
   ${arcRequireBoundVariables}
   typeset object_type 
   while read object_type; do
      if ! [[ -d "${arcGlobalHome}/config/${object_type}" ]]; then
         mkdir "${arcGlobalHome}/config/${object_type}"
      fi
   done < <(file_list_dirs "${arcHome}/config")
   while read object_type; do
      if ! [[ -d "${arcUserHome}/config/${object_type}" ]]; then
         mkdir "${arcUserHome}/config/${object_type}"
      fi
   done < <(file_list_dirs "${arcGlobalHome}/config")
   ${returnTrue} 
}

function test__configPropogateTypesOfObjects {
   mkdir "${arcHome}/config/bar"
   _configPropogateTypesOfObjects 
   echo "${arcGlobalHome}/config/bar" | assert -d 
   mkdir "${arcGlobalHome}/config/baf"
   _configPropogateTypesOfObjects
   echo "${arcUserHome}/config/baf" | assert -d 
}

function config_show_config {
   # Returns some quick/basic info about the objects in the config.
   # >>> config_show_config "object_type" 
   ${arcRequireBoundVariables}
   typeset object_type object_name
   object_type="${1}"
   while read object_name; do
      object_path="$(config_return_object_path "${object_type}" "${object_name}")"
      echo ""
      echo "# ${object_name}"
      str_remove_comments "${object_path}" | utl_remove_blank_lines -stdin
   done < <(config_list_all_objects "${object_type}")
   echo ""
   echo "> config_list_all_objects -a "${object_type}""
   echo ""
   config_list_all_objects -a "${object_type}"
}

function config_edit_object {
   # Open the configuration file for the object in the default editor.
   # >>> config_edit_object "object_type" "object_name"
   ${arcRequireBoundVariables}
   typeset object_type object_name
   object_type="${1}"
   object_name="${2}"
   _configRaiseObjectNotFound "${object_type}" "${object_name}" && ${returnFalse} 
   if [[ -f "${arcUserHome}/config/${object_type}/${object_name}" ]]; then
      "${arcEditor}" "${arcUserHome}/config/${object_type}/${object_name}"
      ${returnTrue} 
   fi
   if ! [[ -f "${arcGlobalHome}/config/${object_type}/${object_name}" ]]; then
      cp "${arcHome}/config/${object_type}" "${arcGlobalHome}/config/${object_type}/${object_name}"
   fi
   "${arcEditor}" "${arcGlobalHome}/config/${object_type}/${object_name}"
   ${returnTrue}  
}

function config_load_object {
   # Return the string required to source in the objects's configuration file.
   # >>> config_load_object "object_type" "object_name"
   ${arcRequireBoundVariables}
   typeset object_type object_name
   utl_raise_invalid_option "config_load_object" "(( $# == 2 ))" && ${returnFalse} 
   object_type="${1}"
   object_name="${2}"
   _configRaiseObjectNotFound "${object_type}" "${object_name}" && ${returnFalse} 
   if [[ -f "${arcUserHome}/config/${object_type}/${object_name}" ]]; then
      echo ". "${arcUserHome}/config/${object_type}/${object_name}""
      ${returnTrue} 
   elif [[ -f "${arcGlobalHome}/config/${object_type}/${object_name}" ]]; then
      echo ". "${arcGlobalHome}/config/${object_type}/${object_name}""
      ${returnTrue} 
   elif [[ -f "${arcHome}/config/${object_type}/${object_name}" ]]; then
      echo ". "${arcHome}/config/${object_type}/${object_name}""
      ${returnTrue} 
   fi
}

function test_config_load_object {
   test_value=0
   eval "$(config_load_object "foo" "foo")"
   echo "${test_value}" | assert 1
}

function config_load_all_objects {
   # Return the strings required to source in the objects's configuration file.
   # >>> config_load_all_objects [-reverse,-r] "object_type" "object_name"
   ${arcRequireBoundVariables}
   typeset object_type object_name reverse_option object_home
   reverse_option=0
   while (( $# > 0)); do
      case "${1}" in
         "-reverse"|"-r") reverse_option=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "config_load_all_objects" "(( $# == 2 ))" "$*" && ${returnFalse}
   object_type="${1}"
   object_name="${2}"
   _configRaiseObjectNotFound "${object_type}" "${object_name}" && ${returnFalse} 
   if (( ${reverse_option} )); then
      while read object_path; do
         echo ". "${object_path}""
      done < <(config_return_all_paths_for_object "${object_type}" "${object_name}" | str_reverse_cat -stdin)
   else
      while read object_path; do
         echo ". "${object_path}""
      done < <(config_return_all_paths_for_object "${object_type}" "${object_name}")
   fi
}

function config_return_all_paths_for_object {
   # Return the full path to all files of object type and object name. 
   # >>> config_return_all_paths_for_object "object_type" "object_name"
   ${arcRequireBoundVariables}
   debug3 "config_return_all_paths_for_object: $*"
   utl_raise_invalid_option "config_return_all_paths_for_object" "(( $# == 2 ))" && ${returnFalse} 
   typeset object_type object_name h
   object_type="${1}"
   object_name="${2}"
   for h in "${arcHome}" "${arcGlobalHome}" "${arcUserHome}"; do
      if [[ -f "${h}/config/${object_type}/${object_name}" ]]; then
         echo "${h}/config/${object_type}/${object_name}"
      fi
   done
   ${returnTrue} 
}

function config_return_object_path {
   # Return the full path to the file which defines the "object".
   # >>> config_return_object_path "object_type" "object_name"
   ${arcRequireBoundVariables}
   debug3 "config_return_object_path: $*"
   typeset object_type object_name 
   utl_raise_invalid_option "config_return_object_path" "(( $# == 2 ))" && ${returnFalse} 
   object_type="${1}"
   object_name="${2}"
   if [[ -f "${arcUserHome}/config/${object_type}/${object_name}" ]]; then
      echo "${arcUserHome}/config/${object_type}/${object_name}"
      ${returnTrue} 
   elif [[ -f "${arcGlobalHome}/config/${object_type}/${object_name}" ]]; then
      echo "${arcGlobalHome}/config/${object_type}/${object_name}"
      ${returnTrue} 
   elif [[ -f "${arcHome}/config/${object_type}/${object_name}" ]]; then
      echo "${arcHome}/config/${object_type}/${object_name}"
      ${returnTrue} 
   else
      _configRaiseObjectNotFound "${object_type}" "${object_name}" 
      ${returnFalse} 
   fi
}

function config_copy_object {
   # Copies an object.
   # >>> config_copy_object "object_type" "object_name" "new_name"
   ${arcRequireBoundVariables}
   utl_raise_invalid_option "config_copy_object" "(( $# == 3 ))" "$*" && ${returnFalse} 
   typeset object_type object_name new_name object_path dir_path
   object_type="${1}"
   object_name="${2}"
   new_name="${3}"
   if config_does_object_exist "${object_type}" "${new_name}"; then
      _configThrowError "'${new_name}' already exists: $*: config_copy_object"
      ${returnFalse} 
   fi
   object_path="$(config_return_object_path "${object_type}" "${object_name}")"
   dir_path="$(dirname "${object_path}")"
   if [[ -f "${object_path}" ]]; then
      cp "${object_path}" "${dir_path}/${new_name}"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function config_list_all_objects {
   # Returns each object of "object type".
   # >>> config_list_all_objects [-l|-a] "object_type"
   # -l: Returns full path to file which defines the object.
   # -a: Returns all objects, even if they are defined more than once.
   ${arcRequireBoundVariables}
   debug3 "config_list_all_objects: $*"
   typeset object_type list_long list_all 
   list_long=0
   list_all=0
   while (( $# > 0)); do
      case "${1}" in
         "-l") list_long=1 ;;
         "-a") list_all=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "config_list_all_objects" "(( $# == 1 ))" && ${returnFalse} 
   object_type="${1}"
   if (( ${list_all} )); then
      _configListEveryObject "${object_type}"
      ${returnTrue} 
   elif (( ${list_long} )); then
      _configListAllObjectsLong "${object_type}" && ${returnTrue} 
   else
      _configListAllObjectsShort "${object_type}" && ${returnTrue} 
   fi
   ${returnFalse} 
}

function test_config_list_all_objects {
   config_list_all_objects "foo" | egrep "foo|bar" | assert -l 2
}

function _configListAllObjectsShort {
   # Return a unique list of all defined objects.
   # >>> _configListAllObjectsShort "object_type"
   ${arcRequireBoundVariables}
   utl_raise_invalid_option "_configListAllObjectsShort" "(( $# == 1 ))" && ${returnFalse} 
   typeset object_type  
   object_type="${1}"
   (
   if [[ -d "${arcHome}/config/${object_type}" ]]; then
      file_list_files "${arcHome}/config/${object_type}"
   fi
   if [[ -d "${arcGlobalHome}/config/${object_type}" ]]; then
      file_list_files "${arcGlobalHome}/config/${object_type}"
   fi
   if [[ -d "${arcUserHome}/config/${object_type}" ]]; then
      file_list_files "${arcUserHome}/config/${object_type}"
   fi
   ) | sort -u
   ${returnTrue} 
}

function _configListAllObjectsLong {
   # Returns the full path to the objects for this object type.
   # >>> _configListAllObjectsLong "object_type"
   ${arcRequireBoundVariables}
   utl_raise_invalid_option "_configListAllObjectsLong" "(( $# == 1 ))" && ${returnFalse} 
   typeset object_type object_name 
   object_type="${1}"
   while read object_name; do
      config_return_object_path "${object_type}" "${object_name}"
   done < <(_configListAllObjectsShort "${object_type}")
   ${returnTrue} 
}

function _configListEveryObject {
   # Returns full path to all Objects at each level of scope.
   # >>> _configListEveryObject "object_type"
   ${arcRequireBoundVariables}
   utl_raise_invalid_option "_configListEveryObject" "(( $# == 1 ))" && ${returnFalse} 
   typeset object_type  
   object_type="${1}"
   echo "\${arcHome}: '${arcHome}/config/${object_type}'"
   if [[ -d "${arcHome}/config/${object_type}" ]]; then
      file_list_files -l "${arcHome}/config/${object_type}" 
   fi
   echo "\${arcGlobalHome}: '${arcGlobalHome}/config/${object_type}'"
   if [[ -d "${arcGlobalHome}/config/${object_type}" ]]; then
      file_list_files -l "${arcGlobalHome}/config/${object_type}" 
   fi
   echo "\${arcUserHome}: '${arcUserHome}/config/${object_type}'"
   if [[ -d "${arcUserHome}/config/${object_type}" ]]; then
      file_list_files -l "${arcUserHome}/config/${object_type}" 
   fi
   ${returnTrue} 
}

function config_list_all_object_types {
   # Return the list of object types that are available.
   # >>> config_list_all_object_types 
   (
   if [[ -d "${arcHome}/config" ]]; then
      file_list_dirs "${arcHome}/config"
   fi
   if [[ -d "${arcGlobalHome}/config" ]]; then
      file_list_dirs "${arcGlobalHome}/config"
   fi
   if [[ -d "${arcUserHome}/config" ]]; then
      file_list_dirs "${arcUserHome}/config"
   fi
   ) | sort -u
}

function config_object_count {
   # Return the number of objects defined.
   # >>> config_object_count "object_type"
   typeset object_type 
   utl_raise_invalid_option "config_object_count" "(( $# == 1 ))" && ${returnFalse} 
   object_type="${1}"
   config_list_all_objects "${object_type}" | wc -l
}

function test_config_object_count {
   config_object_count "foo" | assert ">=2"
}

function config_does_object_exist  {
   # Return true if the object exists.
   # >>> config_does_object_exist "object_type" "object_name"
   ${arcRequireBoundVariables}
   typeset object_type object_name object_file
   utl_raise_invalid_option "config_does_object_exist" "(( $# == 2 ))" && ${returnFalse} 
   object_type="${1}"
   object_name="${2}"
   while read object_file; do
      ${returnTrue} 
   done < <(config_return_all_paths_for_object "${object_type}" "${object_name}")
   ${returnFalse} 
}

function test_config_does_object_exist {
   config_does_object_exist "foo" "foo" && pass_test || fail_test 
   ! config_does_object_exist "x" "foo" && pass_test || fail_test 
}

function _configRaiseObjectNotFound {
   # Return error and return true if the object is not found.
   # >>> _configRaiseObjectNotFound "object_type" "object_name"
   ${arcRequireBoundVariables}
   typeset object_type object_name
   utl_raise_invalid_option "_configRaiseObjectNotFound" "(( $# == 2 ))" && ${returnFalse} 
   object_type="${1}"
   object_name="${2}"
   if ! config_does_object_exist "${object_type}" "${object_name}"; then
      _configThrowError "Object not found: $*: _configRaiseObjectNotFound"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test__configRaiseObjectNotFound {
   _configRaiseObjectNotFound "foo" "foo" 2>&1 | assert -l 0
   _configRaiseObjectNotFound "foo" "bit" 2>&1 | assert_match "ERROR"
   _configRaiseObjectNotFound "bit" "bit" 2>&1 | assert_match "ERROR"
}

function _configThrowError {
   # Return an error message to standard error.
   # _configThrowError "error_message"
   throw_error "arcshell_config" "${1}" 
}

function _configDeleteObjectType {
   # Delete all objects of the referenced object type.
   # >>> _configDeleteObjectType "object_type"
   ${arcRequireBoundVariables}
   typeset object_type 
   utl_raise_invalid_option "_configDeleteObjectType" "(( $# == 1 ))" && ${returnFalse} 
   object_type="${1}"
   if [[ -d "${arcHome}/config/${object_type}" ]]; then
      rm -rf "${arcHome}/config/${object_type}"
   fi
   if [[ -d "${arcGlobalHome}/config/${object_type}" ]]; then
      rm -rf "${arcGlobalHome}/config/${object_type}"
   fi
   if [[ -d "${arcUserHome}/config/${object_type}" ]]; then
      rm -rf "${arcUserHome}/config/${object_type}"
   fi
   ${returnTrue} 
}

function config_delete_object {
   # Delete an object by name.
   # >>> config_delete_object "object_type" "object_name"
   ${arcRequireBoundVariables}
   typeset object_type object_name object_deleted object_file
   utl_raise_invalid_option "config_delete_object" "(( $# == 2 ))" && ${returnFalse} 
   object_type="${1}"
   object_name="${2}"
   object_deleted=0
   while read object_file; do
      rm -f "${object_file}"
      object_deleted=1
   done < <(config_return_all_paths_for_object "${object_type}" "${object_name}")
   if (( ${object_deleted} )); then
      ${returnTrue} 
   else
      _configThrowError "'${object_name}' not found: $*: config_delete_object"
      ${returnFalse} 
   fi
}

function test_file_teardown {
   _configDeleteObjectType "foo"
   _configDeleteObjectType "bar"
   _configDeleteObjectType "baf"
}
