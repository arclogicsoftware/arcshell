
# module_name="SSH"
# module_about="Manage ssh connections and execute remote scripts or commands."
# module_version=1
# module_image="cloud-computing-1.png"
# copyright_notice="Copyright 2019 Arclogic Software"

[[ -z "${arcTmpDir}" ]] && return

# ToDo: Add more logging and log errors.
# ToDo: Need to add option to get a success/failure record back for each node.
# ToDo: Need option to quit on first failure.
# ToDo: Need option to run last command against failed nodes only.
# ToDo: Add "-ssh 'foo,bar'"" support.

function ssh_copy {
   # Copy a file or directory to one or more nodes.
   # >>> ssh_copy [-local,-l] [-ssh,-s "X"] "source_path" ["target_path"]
   # -local: Action can be applied locally if it is an included node.
   # -ssh: SSH user@hostname, alias, tag, or group.
   # source_path: Path to local file or directory to copy.
   # target_path: File or directory to copy source_path to. Defaults to user's home.
   ${arcRequireBoundVariables}
   debug3 "ssh_copy: $*"
   typeset allow_local ssh_connection source_path target_path 
   allow_local=0
   ssh_connection="${_g_sshConnection:-}"
   while (( $# > 0)); do
      case "${1}" in
         "-local"|"-l") allow_local=1 ;;
         "-ssh"|"-s") shift; ssh_connection="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_empty_var "SSH connection is not set. Use -ssh option." "${ssh_connection}" && ${returnFalse}
   utl_raise_invalid_option "ssh_copy" "(( $# <= 2 ))" "$*" && ${returnFalse} 
   source_path="${1}"
   target_path="${2:-}"
   if _sshCopy ${allow_local} "${ssh_connection}" "${source_path}" "${target_path:-}"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _sshCopy {
   # Copy a file or directory to one or more nodes.
   # >>> _sshCopy allow_local "ssh_connection" "source_path" ["target_path"]
   # allow_local: 0 or 1. Action can be applied locally if it is an included node when 1.
   # ssh_connection: SSH user@hostname, alias, tag, or group.
   # source_path: Path to local file or directory to copy.
   # target_path: File or directory to copy source_path to. Defaults to user's home.
   ${arcRequireBoundVariables}
   debug3 "_sshCopy: $*"
   typeset allow_local ssh_connection source_path target_path recursive_permissions_option ssh_node ssh_connection errors 
   allow_local=${1}
   ssh_connection="${2}"
   source_path="${3}"
   target_path="${4:-}"
   if [[ -d "${source_path}" ]]; then
      file_raise_dir_not_found "${source_path}" && ${returnFalse} 
      recursive_permissions_option="-rp "
   else 
      file_raise_file_not_found "${source_path}" && ${returnFalse}
      recursive_permissions_option=
   fi
   errors=0
   while read ssh_node; do
      _sshIsNodeLocalHost "${ssh_node}" && (( ! ${allow_local} )) && continue
      if ! _sshCopyToNode "${ssh_node}" "${source_path}" "${target_path:-}"; then
         ((errors=errors+1))
      fi
   done < <(_sshListMembers "${ssh_connection}")
   if (( ${errors} )); then
      ${returnFalse} 
   else
      ${returnTrue} 
   fi
}

function test__sshCopy {
   typeset f
   f="/tmp/foo$$"
   echo "$$" > "${f}"
   _sshCopy 0 "test@$(hostname)" "${f}" && pass_test || fail_test 
   _sshRunCommandOnTarget 0 "test@$(hostname)" "cat \${HOME}/foo$$" | assert_match "$$" 
   rm -rf "${f}"
}

function _sshCopyToNode {
   # Copy a file or directory to a node.
   # >>> _sshCopyToNode "ssh_node" "source_path" ["target_path"]
   # ssh_node: SSH user@hostname.
   # source_path: Path to local file or directory to copy.
   # target_path: File or directory to copy source_path to. Defaults to user's home.
   ${arcRequireBoundVariables}
   debug3 "_sshCopyToNode: $*"
   typeset source_path target_path recursive_permissions_option ssh_node errors
   ssh_node="${1}"
   source_path="${2}"
   target_path="${3:-}"
   recursive_permissions_option=
   errors=0
   if [[ -d "${source_path}" ]]; then
      file_raise_dir_not_found "${source_path}" && ${returnFalse} 
      recursive_permissions_option="-rp "
   else 
      file_raise_file_not_found "${source_path}" && ${returnFalse}
   fi
   eval "$(ssh_load "${ssh_node}")" || ${returnFalse} 
   if _sshIsNodeLocalHost "${ssh_node}"; then
      if ! [[ "${source_path}" -ef "${target_path:-}" ]]; then
         log_terminal "Copying '${source_path}' to '${target_path:-${HOME}}'..."
         cp ${recursive_permissions_option} "${source_path}" "${target_path:-${HOME}}" 
         errors=$? 
      fi
   else
      _sshSetSSHPASS "${ssh_node}"
      log_terminal "Copying '${source_path}' to '${ssh_node}:${target_path}'..."
      if [[ -n "${node_ssh_key:-}" ]]; then
         ${SSHPASSPROG:-} scp ${recursive_permissions_option} -i "${node_ssh_key}" -P "${node_port}" "${source_path}" "${ssh_node}:${target_path}" < /dev/null
         errors=$? 
      else
         ${SSHPASSPROG:-} scp ${recursive_permissions_option} -P "${node_port}" "${source_path}" "${ssh_node}:${target_path}" < /dev/null
         errors=$? 
      fi
   fi
   if (( ${errors} )); then
      _sshThrowError "An error occured: $*: _sshCopyToNode"
      echo "${ssh_node}:errors"
      ${returnFalse} 
   else
      echo "${ssh_node}:success"
      ${returnTrue} 
   fi
}

function ssh_run_cmd {
   # Run a command on the targeted nodes.
   # >>> ssh_run_cmd [-local,-l] [-ssh,-s "X"] "command"
   # -local: Action can be applied locally if it is an included node.
   # -ssh: SSH user@hostname, alias, tag, or group.
   # command: The command to run.
   ${arcRequireBoundVariables}
   debug3 "ssh_run_cmd: $*"
   typeset allow_local load_arcshell ssh_connection command 
   allow_local=0
   load_arcshell=0
   command=
   ssh_connection="${_g_sshConnection:-}"
   while (( $# > 0)); do
      case "${1}" in
         "-local"|"-l") allow_local=1 ;;
         "-arcshell"|"-a") load_arcshell=1 ;;
         "-ssh"|"-s") shift; ssh_connection="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_empty_var "SSH connection is not set. Use -ssh option." "${ssh_connection}" && ${returnFalse}
   utl_raise_invalid_option "ssh_run_cmd" "(( $# == 1 ))" "$*" && ${returnFalse} 
   command="${1}"
   if _sshRunCommandOnTargets ${load_arcshell} ${allow_local} ${ssh_connection} "${command}" ; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test_ssh_run_cmd {
   ssh_unset
   ssh_run_cmd "echo foo" 2>&1 | assert_match "ERROR"
   ssh_set "test@$(hostname)"
   ssh_run_cmd "echo foo" 2>&1 | grep "foo" | assert -l 1
   ssh_run_cmd -ssh "test" "echo foo" 2>&1 | grep "foo" | assert -l 1
   ssh_run_cmd -ssh "test@$(hostname)" "echo foo" 2>&1 | grep "foo" | assert -l 1
   ssh_set "${arcNode}"
   ssh_run_cmd -local "echo foo" 2>&1 | grep "foo" | assert -l 1 "Should be able to run ssh command against localhost."
}

function _sshRunCommandOnTargets {
   # Run a command on all targeted nodes.
   # >>> _sshRunCommandOnTargets "load_arcshell" "allow_local" "ssh_connection" "command"
   # load_arcshell: 0 or 1. Load ArcShell on target before running command when 1.
   # allow_local: 0 or 1. Action can be applied locally if it is an included node when 1.
   # ssh_connection: SSH user@hostname, alias, tag, or group.
   # command: The command to run.
   ${arcRequireBoundVariables}
   debug3 "_sshRunCommandOnTargets: $*"
   typeset load_arcshell allow_local ssh_connection command errrors ssh_node
   utl_raise_invalid_option "_sshRunCommandOnTargets" "(( $# == 4 ))" "$*" && ${returnFalse} 
   load_arcshell=${1}
   allow_local=${2}
   ssh_connection="${3}"
   command="${4}"
   errors=0
   while read ssh_node; do
      _sshIsNodeLocalHost "${ssh_node}" && (( ! ${allow_local} )) && continue
      if ! _sshRunCommandOnTarget ${load_arcshell} "${ssh_node}" "${command}"; then
         ((errors=errors+1))
      fi
   done < <(_sshListMembers "${ssh_connection}")
   if (( ${errors} )); then
      ${returnFalse} 
   else
      ${returnTrue} 
   fi
}

function _sshRunCommandOnTarget {
   # Runs a command on the target and return exit status.
   # >>> _sshRunCommandOnTarget load_arcshell "ssh_node" "command"
   # load_arcshell: 0 or 1. Load ArcShell on target before running command when 1.
   # ssh_node: SSH user@hostname.
   # command: The command to run.
   ${arcRequireBoundVariables}
   debug3 "_sshRunCommandOnTarget: $*"
   utl_raise_invalid_option "_sshRunCommandOnTarget" "(( $# == 3 ))" "$*" && ${returnFalse} 
   typeset command ssh_node errors load_arcshell node_shell
   load_arcshell=${1}
   ssh_node="$(_sshXREF "${2}")"
   command="${3}"
   (( ${load_arcshell} )) && command=". \${HOME}/.arcshell; ${command}"
   errors=0
   tmpFile="$(mktempf)"
   eval "$(ssh_load "${ssh_node}")"
   if [[ -n "${node_shell:-}" ]]; then
      echo "#!${node_shell}" > "${tmpFile}" 
   fi
   if (( ${load_arcshell} )); then
      echo ". \${HOME}/.arcshell" >> "${tmpFile}"
   fi
   echo "${command}" >> "${tmpFile}"
   if _sshIsNodeLocalHost "${ssh_node}"; then
      chmod 700 "${tmpFile}"
      "${tmpFile}"
      errors=$?
      # ! eval "${command}" && errors=1
   else
      # echo "${command}" | ssh "${ssh_node}" -p ${node_port} "${node_shell:-"\$0"}"
      _sshSetSSHPASS "${ssh_node}"
      if ! ${SSHPASSPROG:-} ssh "${ssh_node}" -p ${node_port} "${node_shell:-"\$0"}" < "${tmpFile}"; then
         errors=1
      fi
      # if ! ${SSHPASSPROG:-} ssh "${ssh_node}" -p ${node_port} "${command}" < /dev/null; then
      #    errors=1
      # fi
   fi
   rm "${tmpFile}"
   if (( ${errors} )); then
      ${returnFalse}
   else 
      ${returnTrue} 
   fi
}

# ToDo: Add option to load ArcShell.
# ToDo: May need option to specify shell if bash/korn not default shell.

function ssh_run_file {
   # Run a file on all of the targeted nodes.
   # >>> ssh_run_file [-local,-l] [-ssh,-s "X"] "file_path" 
   # -local: Action can be applied locally if it is an included node.
   # -ssh: SSH user@hostname, alias, tag, or group.
   # file_path: Path to local file which will be run against selected nodes.
   ${arcRequireBoundVariables}
   debug3 "ssh_run_file: $*"
   typeset allow_local ssh_connection file_path 
   allow_local=0
   ssh_connection="${_g_sshConnection:-}"
   while (( $# > 0)); do
      case "${1}" in
         "-local"|"-l") allow_local=1 ;;
         "-ssh"|"-s") shift; ssh_connection="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_empty_var "SSH connection is not set. Use -ssh option." "${ssh_connection}" && ${returnFalse}
   utl_raise_invalid_option "ssh_run_file" "(( $# == 1 ))" "$*" && ${returnFalse} 
   file_path="${1}"
   file_raise_file_not_found "${file_path}" && ${returnFalse} 
   if _sshRunFile ${allow_local} "${ssh_connection}" "${file_path}"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _sshRunFile {
   # Run a file on one or more nodes.
   # >>> _sshRunFile allow_local "ssh_connection" "file_path"
   # allow_local: 0 or 1. Action can be applied locally if it is an included node when 1.
   # ssh_connection: SSH user@hostname, alias, tag, or group.
   # file_path: Path to local file which will be run against selected nodes.
   ${arcRequireBoundVariables}
   debug3 "_sshRunFile: $*"
   typeset allow_local ssh_connection file_path errors ssh_node
   allow_local=${1}
   ssh_connection="${2}"
   file_path="${3}"
   errors=0
   file_raise_file_not_found "${file_path}" && ${returnFalse}
   while read ssh_node; do
      _sshIsNodeLocalHost "${ssh_node}" && (( ! ${allow_local} )) && continue
      if ! _sshRunFileAtNode ${allow_local} "${ssh_node}" "${file_path}" < /dev/null; then
         ((errors=errors+1))
      fi
   done < <(_sshListMembers "${ssh_connection}")
   if (( ${errors} )); then
      ${returnFalse}
   else
      ${returnTrue}
   fi
}

# ToDo: This function needs some work.

function _sshRunFileAtNode {
   # Run a file on an SSH node.
   # >>> _sshRunFileAtNode allow_local "ssh_node" "file_path"
   # allow_local: 0 or 1. Action can be applied locally if it is an included node when 1.
   # ssh_node: SSH user@hostname.
   # file_path: Path to local file which will be run against selected node.
   ${arcRequireBoundVariables}
   debug3 "_sshRunFileAtNode: $*"
   typeset allow_local ssh_node file_path errors tmpFile run_file ssh_node
   allow_local=${1}
   ssh_node="${2}"
   file_path="${3}"
   errors=0
   tmpFile="$(mktempf)"
   eval "$(ssh_load "${ssh_node}")" || ${returnFalse} 
   if [[ -n "${node_shell:-}" ]]; then
      echo "#!${node_shell}" > "${tmpFile}"
   fi
   cat "${file_path}" >> "${tmpFile}"
   echo "" >> "${tmpFile}"
   chmod 700 "${tmpFile}"
   run_file="$(basename "${tmpFile}")"
   if _sshIsNodeLocalHost "${ssh_node}"; then
      if (( ${allow_local} )); then
         "${tmpFile}"
         errors=$?
      fi
   elif [[ -f "${node_ssh_key:-}" ]]; then
      _sshSetSSHPASS "${ssh_node}"
      ${SSHPASSPROG:-} ssh -t -i "${node_ssh_key}" "${ssh_node}" -p ${node_port} "$(cat ${file_path})" < /dev/null
      errors=$?
   else
      # File needs to be copied over first so we can inject the shbang else 
      # default shell which may be "sh" tries to run the file.
      # _sshCopyToNode "${ssh_node}" "${tmpFile}" || ${returnFalse} 
      _sshSetSSHPASS "${ssh_node}"
      ${SSHPASSPROG:-} ssh "${ssh_node}" -p ${node_port} "${node_shell:-"\$0"}" < "${tmpFile}"
      #${SSHPASSPROG:-} ssh -T "${ssh_node}" -p ${node_port} "./${run_file}"
      errors=$?
      #_sshRunCommandOnTarget 0 "${ssh_node}" "rm "$(basename "${tmpFile}")""
   fi
   rm "${tmpFile}" 2> /dev/null
   if (( ${errors} )); then
      log_error -2 -logkey "ssh" "Error: $*: _sshRunFileAtNode"
      ${returnFalse}
   else
      ${returnTrue}
   fi
}

function ssh_connect {
   # Connect to a node using SSH.
   # >>> ssh_connect [-ssh "X"|"regex"|?]
   # -ssh: SSH user@hostname, alias, tag, or group.
   # regex: Returns a menu of matching SSH connections.
   # ?: Returns a menu of all SSH connections.
   ${arcRequireBoundVariables}
   debug3 "ssh_connect: $*"
         
   typeset ssh_connection use_sshpass regex ssh_node
   ssh_connection="${_g_sshConnection:-}"
   use_sshpass=0
   regex=
   while (( $# > 0)); do
      case "${1}" in
         "-ssh"|"-s") shift; ssh_connection="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "ssh_connect" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   (( $# == 1 )) && ssh_connection="${1}"
   if [[ "${ssh_connection}" == "?" ]]; then
      _sshConnectMenu -regex ".*"
   elif _sshDoesTagExist "${ssh_connection}" || _sshDoesGroupExist "${ssh_connection}"; then
      _sshConnectMenu -ssh "${ssh_connection}"
   elif ! _sshDoesNodeExist "${ssh_connection}" && ! _sshDoesAliasExistStrict "${ssh_connection}"; then
      _sshConnectMenu -regex "${ssh_connection}"
   else
      ssh_node="$(_sshXREF "${ssh_connection}")"
      ssh_set "${ssh_node:-}" || ${returnFalse} 
      _sshRaiseIsNotANodeOrNodeAlias "${ssh_node}" && ${returnFalse} 
      _sshRaiseIsLocalHost "${ssh_node}" && ${returnFalse}
      eval "$(ssh_load "${ssh_node}")"
      _sshSetSSHPASS "${ssh_node}"
      tmpFile="$(mktempf)"
      if [[ -f "${node_ssh_key}" ]]; then
         ${SSHPASSPROG:-} ssh -i "${node_ssh_key}" "${ssh_node}" -p ${node_port} #2> "${tmpFile}.err"
      else
         ${SSHPASSPROG:-} ssh "${ssh_node}" -p ${node_port} #2> "${tmpFile}.err"
      fi
      #_ssh_raise_ssh_error "${tmpFile}.err" 
      rm "${tmpFile}"
   fi
}

function _sshConnectMenu {
   # Returns a menu of available ssh connections.
   # >>> _sshConnectMenu [-regex "X"|-ssh "ssh_connection"]
   # -regex: Returns a menu of matching SSH connections.
   # -ssh_connection: SSH alias, node, group, or tag.
   ${arcRequireBoundVariables}
   debug3 "_sshConnectMenu: $*"
   typeset regex ssh_connection
   ssh_connection="${_g_sshConnection:-}"
   regex=
   while (( $# > 0)); do
      case "${1}" in
         "-regex") shift; regex="${1}" ;;
         "-ssh"|"-s") shift; ssh_connection="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "_sshConnectMenu" "(( $# == 0 ))" "$*" && ${returnFalse}
   menu_create "ssh_connect$$" "Select a connection." 
   if [[ -n "${regex:-}" ]]; then
      while read ssh_alias ssh_connection; do
         _sshIsNodeLocalHost "${ssh_connection}" && continue
         menu_add_text "${ssh_alias} - ${ssh_connection}" "${ssh_connection}"
      done < <(_sshListPretty | egrep -v "^node -" | awk '{print $2" "$1}' | grep "${regex}")
   else
      while read ssh_connection; do 
         _sshIsNodeLocalHost "${ssh_connection}" && continue
         menu_add_text "${ssh_connection}" "${ssh_connection}"
      done < <(_sshListMembers "${ssh_connection}")
   fi
   menu_show -quit "ssh_connect$$"
   if (( $(menu_get_selected_item_count "ssh_connect$$") )); then
      ssh_connection="$(menu_get_selected_item "ssh_connect$$")"
      ssh_connect -ssh "${ssh_connection}"
   fi
   menu_delete "ssh_connect$$"
}

function ssh_check {
   # Validate the health of the current ssh connection.
   # >>> ssh_check [-ssh,-s "X"] [-fix,-f] ["ssh_connection"]
   # -fix: Automatically fixes issues.
   # ssh_connection: Same as '-ssh'.
   ${arcRequireBoundVariables}
   debug3 "ssh_check: $*"
   typeset autofix_option ssh_connection ssh_node
   autofix_option=0
   ssh_connection="${_g_sshConnection:-}"
   while (( $# > 0)); do
      case "${1}" in
         "-ssh"|"-s") shift; ssh_connection="${1}" ;;
         "-fix"|"-f") autofix_option=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "ssh_check" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   (( $# == 1 )) && ssh_connection="${1}" 
   ssh_connection="$(_sshXREF "${ssh_connection}")"
   while read ssh_node; do
      _sshIsNodeLocalHost "${ssh_node}" && continue
      _sshCheckConnection ${autofix_option} "${ssh_node}" 
   done < <(_sshListMembers "${ssh_connection:-}")
   ${returnTrue} 
}

function _sshReturnSSHKeyFilePath {
   # Returns full path to ssh key file by looking in all possible locations.
   # >>> _sshReturnSSHKeyFilePath "ssh_key_file"
   # ssh_key_file: Can be full path to the file or just the name and we will look for it.
   ${arcRequireBoundVariables}
   utl_raise_invalid_option "_sshReturnSSHKeyFilePath" "(( $# == 1 ))" "$*" && ${returnFalse} 
   typeset ssh_key_file 
   ssh_key_file="${1}" 
   if [[ -f "${ssh_key_file}" ]]; then
      echo "${ssh_key_file}"
      ${returnTrue} 
   fi 
   if [[ -f "${HOME}/.ssh/${ssh_key_file}" ]]; then
      echo "${HOME}/.ssh/${ssh_key_file}"
      ${returnTrue} 
   fi
   if config_return_object_path "ssh_keys" "${ssh_key_file}"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test__sshReturnSSHKeyFilePath {
   touch "${arcUserHome}/config/ssh_keys/foo.pem"
   _sshReturnSSHKeyFilePath "foo" 2>&1 | assert_match "ERROR" "Trying to return a key which does not exist should throw an error."
   _sshReturnSSHKeyFilePath "foo.pem" | assert -f 
   _sshReturnSSHKeyFilePath "${arcUserHome}/config/ssh_keys/foo.pem" | assert -f
   rm "${arcUserHome}/config/ssh_keys/foo.pem"
}

function _sshCheckConnection {
   # Validate the health of the an ssh connection.
   # >>> _sshCheckConnection autofix_option "ssh_node_or_alias"
   # autofix_option: Automatically fixes issues.
   # ssh_node_or_alias: SSH user@host or alias.
   ${arcRequireBoundVariables}
   debug3 "_sshCheckConnection: $*"
   utl_raise_invalid_option "_sshCheckConnection" "(( $# == 2 ))" "$*" && ${returnFalse} 
   typeset autofix_option tmpFile ssh_node allow_local
   autofix_option=${1}
   ssh_node="$(_sshXREF "${2}")" || ${returnFalse} 
   tmpFile="$(mktempf)"
   (
   echo "_ssh_check_fix=${autofix_option}" 
   cat "${arcHome}/sh/core/_ssh_check.sh" 
   ) > "${tmpFile}"
   chmod 700 "${tmpFile}"
   log_terminal "Checking ssh configuration for '${ssh_node}'..."
   if _sshRunFile ${allow_local:-1} "${ssh_node}" "${tmpFile}"; then
      rm "${tmpFile}"      
      ${returnTrue} 
   else
      rm "${tmpFile}"
      ${returnFalse} 
   fi
}

function ssh_send_key {
   # Copy contents of ~/.ssh/id_rsa.pub to the current connection's authorized keys file.
   # Note: Function can be run multiple times, key is only added if it is not there.
   # >>> ssh_send_key [-ssh "X"] [-force] ["ssh_connection"]
   # -force: Update authorized_keys entry even if key is already in file.
   # ssh_connection: Same as '-ssh'.
   ${arcRequireBoundVariables}
   debug3 "ssh_send_key: $*"
   typeset x tmpFile _ssh_force_key ssh_connection errors
   _ssh_force_key=0
   ssh_connection="${_g_sshConnection:-}"
   errors=0
   while (( $# > 0)); do
      case "${1}" in
         "-ssh"|"-s") shift; ssh_connection="${1}" ;;
         "-force"|"-f") _ssh_force_key=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "ssh_send_key" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   (( $# == 1 )) && ssh_connection="${1}"
   while read ssh_node; do
      _sshIsNodeLocalHost "${ssh_node}" && continue
      _sshRaiseIdRsaPubFileNotFound && continue
      tmpFile="$(mktempf)"
      x="$(cat "${HOME}/.ssh/id_rsa.pub")"
      (
      echo "_ssh_public_key=\"${x}\"" 
      echo "_ssh_force_key=${_ssh_force_key}"
      cat "${arcHome}/sh/core/_ssh_add_key.sh"
      ) >> "${tmpFile}"
       if ! _sshRunFile ${allow_local:-0} "${ssh_connection}" "${tmpFile}"; then
         ((errors=errors+1))
      fi
      rm "${tmpFile}"
   done < <(_sshListMembers "${ssh_connection}")
   if (( ${errors} )); then
      ${returnFalse} 
   else
      ${returnTrue} 
   fi
}

function _sshListMembers {
   # Return member list for current connection (works for node, alias, group, or tag).
   # >>> _sshListMembers "ssh_connection"
   # ssh_connection: SSH user@hostname, alias, tag, or group.
   ${arcRequireBoundVariables}
   typeset ssh_connection
   debug3 "_sshListMembers: $*"
   if (( $# == 1 )); then
      ssh_connection="$(_sshXREF "${1:-}")"
   else
      ssh_connection="$(_sshXREF "${_g_sshConnection:-}")"
   fi
   if _sshDoesGroupExist "${ssh_connection}"; then
      ssh_return_nodes_in_group "${ssh_connection}" 
      ${returnTrue} 
   elif _sshDoesNodeExist "${ssh_connection}"; then
      echo "${ssh_connection}" 
      ${returnTrue} 
   elif _sshDoesTagExist "${ssh_connection}"; then
      ssh_return_nodes_with_tag "${ssh_connection}"
      ${returnTrue} 
   else
      _sshThrowError "Connection not found: '$*': _sshListMembers"
      ${returnFalse} 
   fi
}

function ssh_get_key {
   # Get contents from remote ~/.ssh/id_rsa.pub and add it to local authorized_keys file.
   # >>> ssh_get_key [-force,-f] [-ssh "X"] ["ssh_connection"]
   # -force: Update authorized_keys entry even if key is already in file.
   # -ssh: SSH user@hostname, alias, tag, or group.
   # ssh_connection: SSH user@hostname, alias, tag, or group.
   ${arcRequireBoundVariables}
   debug3 "ssh_get_key: $*"
   typeset ssh_connection ssh_node errors
   # Don't scope this locally! Must be exported to the _ssh_add_key.sh script.
   _ssh_force_key=0
   ssh_connection="${_g_sshConnection:-}"
   errors=0
   while (( $# > 0)); do
      case "${1}" in
         "-ssh"|"-s") shift; ssh_connection="${1}" ;;
         "-f"|"-force") _ssh_force_key=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "ssh_get_key" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   (( $# == 1 )) && ssh_connection="${1}"
   while read ssh_node; do
      _sshIsNodeLocalHost "${ssh_node}" && continue
      _ssh_public_key="$(_sshRunCommandOnTarget 0 "${ssh_node}" "cat \${HOME}/.ssh/id_rsa.pub" | grep "^ssh-")"
      utl_raise_empty_var "Failed to get a public key from remote id_rsa.pub file." "${_ssh_public_key}" && continue
      export _ssh_public_key
      export _ssh_force_key
      . "${arcHome}/sh/core/_ssh_add_key.sh"
      if (( $? )); then
         ((errors=errors+1))
      fi
   done < <(_sshListMembers "${ssh_connection}")
   if (( ${errors} )); then
      ${returnFalse} 
   else
      ${returnTrue} 
   fi
}

function ssh_swap_keys {
   # Run both ssh_send_key and ssh_get_key.
   # >>> ssh_swap_keys [-force,-f] [-ssh,-s "X"] ["ssh_connection"]
   # -force: Update authorized_keys entry even if key is already in files.
   # -ssh: SSH user@hostname, alias, tag, or group.
   # ssh_connection: SSH user@hostname, alias, tag, or group.
   ${arcRequireBoundVariables}
   typeset force_option ssh_connection ssh_node errors 
   force_option=
   ssh_connection="${_g_sshConnection:-}"
   errors=0
   while (( $# > 0)); do
      case "${1}" in
         "-ssh"|"-s") shift; ssh_connection="${1}" ;;
         "-f"|"-force") force_option="-f" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "ssh_swap_keys" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   (( $# == 1 )) && ssh_connection="${1}"
   while read ssh_node; do
      if ! ssh_send_key ${force_option} "${ssh_node}"; then
         ((errors=errors+1))
      fi
      if ! ssh_get_key ${force_option} "${ssh_node}"; then
         ((errors=errors+1))
      fi
   done < <(_sshListMembers "${ssh_connection}")
   if (( ${errors} )); then
      ${returnFalse} 
   else
      ${returnTrue} 
   fi
}

function ssh_does_dir_exist {
   # Return true if a remote directory exists.
   # >>> ssh_does_dir_exist [-ssh "X"] "directory"
   # -ssh: SSH user@hostname or alias.
   # directory: Full or relative path of directory you want to check for.
   ${arcRequireBoundVariables}
   debug3 "ssh_does_dir_exist: $*"
   typeset directory ssh_connection
   ssh_connection="${_g_sshConnection:-}"
   while (( $# > 0)); do
      case "${1}" in
         "-ssh"|"-s") shift; ssh_connection="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "ssh_does_dir_exist" "(( $# == 1 ))" "$*" && ${returnFalse} 
   _sshRaiseIsNotANodeOrNodeAlias "${ssh_connection:-}" && ${returnFalse}
   directory="${1}"
   if _sshRunCommandOnTarget 0 "${ssh_connection}" "[[ -d "${directory}" ]] && exit 0 || exit 1"; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_ssh_does_dir_exist {
   ssh_does_dir_exist -ssh "test" "/tmp" && pass_test || fail_test 
   ! ssh_does_dir_exist -ssh "test" "/x" && pass_test || fail_test 
}

function ssh_get_home {
   # Return the home directory path for a node or group of nodes.
   # >>> ssh_get_home [-ssh "X"] ["ssh_node_or_alias"]
   # -ssh: SSH user@hostname or alias.
   # ssh_node_or_alias: SSH user@hostname or alias.
   ${arcRequireBoundVariables}
   typeset ssh_node_or_alias 
   ssh_node_or_alias="${_g_sshConnection:-}"
    while (( $# > 0)); do
      case "${1}" in
         "-ssh"|"-s") shift; ssh_node_or_alias="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "ssh_get_home" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   (( $# == 1 )) && ssh_node_or_alias="${1}"
   _sshRunCommandOnTarget 0 "${ssh_node_or_alias:-}" "echo \${HOME}"
}

function _sshRaiseIdRsaPubFileNotFound {
   # Throw error and return true if the id_rsa.pub file is missing.
   # >>> _sshRaiseIdRsaPubFileNotFound
   if ! [[ -f "${HOME}/.ssh/id_rsa.pub" ]]; then
      _sshThrowError "id_rsa.pub not found: $*: _sshRaiseIdRsaPubFileNotFound"
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

# ToDo: Next two functions cause confusion.

function _sshIsNodeLocalHost {
   # Return true if the ssh_node is the local user and host.
   # >>> _sshIsNodeLocalHost "ssh_node"
   # ssh_node: SSH user@hostname.
   ${arcRequireBoundVariables}
   typeset ssh_node
   ssh_node="${1}"
   if [[ "${ssh_node}" == "${arcNode}" ]]; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _sshRaiseIsLocalHost {
   # Throw error and return true when the provided string is the localhost.
   # >>> _sshRaiseIsLocalHost "ssh_node_or_alias"
   # ssh_node_or_alias: SSH user@hostname or alias.
   ${arcRequireBoundVariables}
   typeset ssh_node 
   ssh_node="$(_sshXREF "${1}")" || ${returnFalse} 
   if _sshIsNodeLocalHost "${ssh_node}"; then
      _sshThrowError "This action can not be performed against the local host: $*: _sshRaiseIsLocalHost"
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function _sshRaiseNodeNotFound {
   # Throw error and return true if the provided string is not a node.
   # >>> _sshRaiseNodeNotFound "ssh_node"
   # ssh_node: SSH user@hostname.
   ${arcRequireBoundVariables}
   typeset ssh_node
   ssh_node="${1}"
   if ! _sshDoesNodeExist "${ssh_node}"; then
      _sshThrowError "Node not found: $*: _sshRaiseNodeNotFound"
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function _sshRaiseConnectionNotSet {
   # Throw error and return true if the ssh connection isn't set.
   # >>> _sshRaiseConnectionNotSet 
   ${arcRequireBoundVariables}
   if [[ -z "${_g_sshConnection:-}" ]]; then
      _sshThrowError "Connection not set: $*: _sshRaiseConnectionNotSet"
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function ssh_list_key_types_in_use {
   # Return the list of ssh key types found in the provided directory.
   # >>> ssh_list_key_types_in_use 
   ${arcRequireBoundVariables}
   debug3 "ssh_list_key_types_in_use: $*"
   typeset file
   if [[ -d "${HOME}/.ssh" ]]; then
      (
      while read file; do
         ssh-keygen -l -f "${file}" 2>/dev/null 
      done < <(find "${HOME}/.ssh" -type f -name "id_*")
      ) | awk '{print $4}' | tr -d "()" | sort | uniq
   fi
}

