
# module_name="SSH Connection Manager"
# module_about="SSH connection manager."
# module_version=1
# module_image="id-card-2.png"
# copyright_notice="Copyright 2019 Arclogic Software"

[[ -z "${arcTmpDir}" ]] && return

mkdir -p "${arcHome}/config/ssh_connections"
mkdir -p "${arcGlobalHome}/config/ssh_connections"
mkdir -p "${arcGlobalHome}/config/ssh_groups"

_sshDir="${arcTmpDir}/_ssh_connections"
mkdir -p "${_sshDir}/nodes"
mkdir -p "${_sshDir}/groups"
mkdir -p "${_sshDir}/aliases"
mkdir -p "${_sshDir}/tags"
_g_sshConnection=
SSHPASS=
SSHPASSPROG=
SSHPASSNODE=
_g_use_sshpass=0

# ToDo: Automatically run ssh_refresh in background using delivered task when needed.
# ToDo: Need some sort of group reporting. Groups can be dynamic. So this won't guarantee the same results each time.
# ToDo: Ability to update all ssh keys by 'ssh_connection'.
# ToDo: Detect tag, group, and alias conflicts.

function __readmeSSHConnections {
   cat <<EOF
# SSH Connections

**An SSH connection management module.**

You can save time navigating hosts with SSH and running commands by using this module.

**Features**
* Nodes can be assigned an easy to remember aliases and multiple tags.
* Global connections are available on all ArcShell nodes automatically.
* Dynamic Node Groups 
* Run commands or scripts against one or multiple hosts using aliases, tags, and groups.
* Supports **sshpass** 
* Corrects common SSH key authentication configuration issues.
* Supports use of unique keys.
* Runs on any Unix or Linux host using either the Bash or Korn shell.

 Each connection is created using a simple configuration file in one of these two locations.

\`\`\`\${arcGlobalHome}/config/ssh_connections\`\`\`
\`\`\`\${arcUserHome}/config/ssh_connections\`\`\`

If there are two files only one is loaded. The file in the **user** home has precedence. Files in the **global** home are distributed to the other nodes in your network when you deploy ArcShell. 

This is an example of a configuration file.
\`\`\`
# \${arcHome}/global/config/ssh_connections/${arcNode}.cfg
$(cat ${arcHome}/global/config/ssh_connections/${arcNode}.cfg)
\`\`\`
\`\`\`ssh_add\`\`\` can be used to create connections from the command line or the files can be created manually. Some configuration settings always need to be modified by editing the file directly.

\`\`\`ssh_refresh\`\`\` needs to be executed when a group of changes are complete. This procedure rebuilds the indexes that contain information about the defined tags, aliases, and SSH groups.

\`\`\`ssh_set\`\`\` can be used to set the current SSH connection. It can be set to a specific node, alias, tag, or group. When set you will not need to provide it when running commands.

ArcShell supports SSHPASS if you are on a Linux OS and unable to configure SSH keys. You can set the \`\`\`node_sshpass\`\`\` value in the configuration file for the node to enable this capability when connecting to the node. The \`\`\`sshpass\`\`\` program needs to be installed.

SSH groups are created using an SSH group configuration file. 

\`\`\`\${arcGlobalHome}/config/ssh_groups\`\`\`
\`\`\`\${arcUserHome}/config/ssh_groups\`\`\`

SSH groups are shell scripts ending in \`\`\`.cfg\`\`\` which do the following:
* Return a list of nodes, aliases, and tags which comprise the group when executed.
* Does not return group names! You can end up with a recursive operation very easily!
* Returns members of other groups by using the \`\`\`ssh_return_nodes_in_group\`\`\` function as a work around.

EOF
}

function __setupSSHConnections {
   # Setup function.
   # >>> __setupSSHConnections
   ssh_refresh
   ${returnTrue} 
}

function ssh_add {
   # Add or updates an SSH connection.
   # >>> ssh_add [-port,-p X] [-alias,-a "X"] [-ssh_key,-s "X"] [-tags,-t "X,"] "user@address"
   # -port: SSH port number. Defaults to 22.
   # -alias: An alternative and usually easy name to recall for this connection.
   # -ssh_key: Path to private key file, or file name only if in one of the 'ssh_keys' folders or "\${HOME}/.ssh".
   # -tags: Comma separated list of tags. Tags are one word.
   # user@address: User name and host name or IP address.
   ${arcRequireBoundVariables}
   debug3 "ssh_add: $*"
   typeset port alias ssh_key tags ssh_node target_file
   port=22
   alias=
   tags=
   while (( $# > 0)); do
      case "${1}" in
         "-port"|"-p") shift; port="${1}"        ;;
         "-alias"|"-a") shift; alias="${1}"      ;;
         "-ssh_key"|"-s") shift; ssh_key="${1}"          ;;
         "-tags"|"-t"|"-tag") shift; tags="$(utl_format_tags "${1}")" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "ssh_add" "(( $# == 1 ))" "$*" && ${returnFalse}
   #_sshRaiseInvalidTags "${tags:-}" && ${returnFalse} 
   #_sshRaiseInvalidAlias "${alias:-}" && ${returnFalse} 
   ssh_node="${1}"
   target_file="${arcGlobalHome}/config/ssh_connections/${ssh_node}.cfg"
   echo "" > "${target_file}"
   (
   cat <<EOF
# Generated using 'ssh_add'.

# An alias makes it easy to refer to the node.
node_alias="${alias:-${ssh_node}}"

# One or more tags. Use commas between tags.
node_tags="${tags:-}"

# The ssh port to connect to. Defaults to 22 if not provided.
node_port=${port}

# If Bash or Korn shell is not default shell one of those shells needs to be defined here.
node_shell=

# Private key file path or just the name if it is in your 'ssh_keys' folders.
node_ssh_key="${ssh_key:-}"

# Optionally supply ths SSHPASS value to avoid having to provide it the first time.
node_sshpass=""

EOF
   ) >> "${target_file}"
   log_terminal "'${ssh_node}' has been configured using '${target_file}'."
   ${returnTrue} 
}

function test_ssh_add {
   ssh_add -alias "foo" "foo@bar" && pass_test || fail_test 
   ssh_refresh 
   ssh_list | assert_match "foo@bar"
}

function ssh_refresh {
   # Refreshes the SSH connection database. Should be run after modifications are made.
   # > This will eventually get set up as an automated background task but for now you either need to run setup or ssh_refresh after adding/modifying connections.
   # >>> ssh_refresh
   ${arcRequireBoundVariables}
   debug3 "ssh_refresh: $*"
   typeset ssh_node  
   _sshDeleteSSHConnectionLookups
   _sshAddLocalHost
   tmpFile="$(mktempf)"
   while read ssh_node; do
      eval "$(config_load_object "ssh_connections" "${ssh_node}.cfg")"
      echo "${ssh_node}" > "${_sshDir}/nodes/${ssh_node}"
      [[ -z "${node_alias:-}" ]] && node_alias="${ssh_node}"
      if _sshRaiseDuplicateAlias "${node_alias}"; then
         node_alias="${ssh_node}"
      fi
      echo "${ssh_node}" > "${_sshDir}/aliases/${node_alias}"
      if [[ -n "${node_tags:-}" ]]; then
         while read tag_name; do
            echo "${ssh_node}" >> "${_sshDir}/tags/${tag_name}"
         done < <(echo "${node_tags:-}" | str_split_line -stdin "," | utl_remove_blank_lines -stdin)
      fi
   done < <(_sshListNodes)
   rm "${tmpFile}"*
   log_terminal "SSH connections have been refreshed."
   ${returnTrue} 
}

function test_ssh_refresh {
   ssh_refresh && pass_test || fail_test 
}

function ssh_list {
   # Returns the list of SSH connections.
   # >>> ssh_list [-l]
   # -l: Long list.
   ${arcRequireBoundVariables}
   debug3 "ssh_list: $*"
   case "${1:-}" in 
      "-l") _sshListLong ;;
      *) config_list_all_objects "ssh_connections" | sed 's/\.cfg//';;
   esac
}

function test_ssh_list {
   ssh_list | assert -l ">=5"
}

function ssh_edit {
   # Edit the specified ssh connection config file. Defaults to local node.
   # >>> ssh_edit ["ssh_connection"]
    typeset ssh_node file_path 
   if (( $# )); then
      ssh_node="$(_sshXREF "${1}")"
   else
      ssh_node="${arcNode}"
   fi
   file_path="$(config_return_object_path "ssh_connections" "${ssh_node}")"
   if [[ -f "${file_path}" ]]; then
      ${arcEditor} "${file_path}"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function ssh_set {
   # Sets the current SSH connection. It can be a node, alias, tag, or group.
   # >>> ssh_set "ssh_connection"
   # ssh_connection: SSH user@hostname, alias, tag, or group.
   ${arcRequireBoundVariables}
   debug3 "ssh_set: $*"
   typeset ssh_connection
   if utl_raise_invalid_option "ssh_set" "(( $# == 1 ))" "$*"; then
      ssh_unset 
      ${returnFalse} 
   fi
   ssh_connection="$(_sshXREF "${1}")" || ${returnFalse} 
   if _sshLogGlobalConnectionChange "${ssh_connection}"; then
      _g_sshConnection="${ssh_connection}"
      if ! _sshIsNodeLocalHost "${ssh_connection}" &&  _sshDoesNodeExistStrict "${ssh_connection}"; then
         ssh_pass_reset
         if _sshSetSSHPASS "${ssh_connection}"; then
            ${returnTrue} 
         else
            ${returnFalse} 
         fi
      else
         ${returnTrue} 
      fi
   else
      ${returnTrue} 
   fi
}

function test_ssh_set {
   ssh_add -alias "foo" "foo@bar" && pass_test || fail_test 
   ssh_refresh 
   ssh_set "foo" && pass_test || fail_test "'foo' is a connection we created for testing."
   ssh_set "test" && pass_test || fail_test "'test' is an ArcShell development host connection."
   ssh_set "bar" 2>&1 | assert_match "ERROR" "'bar' is not a valid connection."
}

function ssh_show {
   # Returns the name of the current connection if it has been set. It can be set using ssh_set procedure.
   # >>> ssh_show 
   ${arcRequireBoundVariables}
   if _sshIsConnectionSet; then
      if _sshDoesGroupExist "${_g_sshConnection}"; then
         log_terminal "SSH connection group is set to '${_g_sshConnection}'"
      elif _sshDoesTagExist "${_g_sshConnection}"; then
         log_terminal "SSH connection tag is set to '${_g_sshConnection}'"
      else
         log_terminal "SSH connection is set to '${_g_sshConnection}'"
      fi
   else
      log_terminal "SSH connection is not set."
   fi
}

function test_ssh_show {
   # Note, ssh_show does not return output in testing because tty will be 0 
   # and log_terminal calls will only go to the log file.
   :
}

function ssh_delete {
   # Deletes an SSH connection.
   # >>> ssh_delete "ssh_connection"
   ${arcRequireBoundVariables}
   typeset ssh_node file_path 
   ssh_node="$(_sshXREF "${1}")"
   if config_delete_object "ssh_connections" "${ssh_node}.cfg"; then
      log_terminal "Deleted connection '${ssh_node}'."
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test_ssh_delete {
   _sshDoesNodeExist "foo@bar" && pass_test || fail_test 
   ssh_delete "foo@bar"
   ssh_refresh 
   ! _sshDoesNodeExist "foo@bar" && pass_test || fail_test 
}

function ssh_delete_all_connections {
   # Deletes all connections and rebuilds the local connection.
   # > This can be used if you are rebuilding all of your connections from another source.
   # >>> ssh_delete_all_connections
   log_terminal "Are you sure you want to delete all registered SSH connections?"
   utl_confirm || ${returnFalse} 
   find "${arcUserHome}/config/ssh_connections" -type f -exec rm {} \;
   find "${arcGlobalHome}/config/ssh_connections" -type f -exec rm {} \;
}

function _sshListLong {
   # List SSH nodes. Pretty format: user@host, (alias), and [tags].
   # >>> _sshListLong
   ${arcRequireBoundVariables}
   typeset ssh_node 
   utl_raise_invalid_option "ssh_list" "(( $# == 0 ))" "$*" && ${returnFalse} 
   echo "node ------------------------- alias -------------- tags ---------------------------"
   while read ssh_node; do
      eval "$(ssh_load "${ssh_node}")"
      printf "%-30s %-20s %-28s\n" "${ssh_node}" "(${node_alias})" "$(_sshBracketizeList "${node_tags:-}")"
   done < <(_sshListNodes)
}

function ssh_unset {
   # Unset the current SSH connection.
   # >>> ssh_unset   
   _g_sshConnection=
   SSHPASS=
   SSHPASSPROG=
   log_terminal "Unsetting ssh connection."
   ${returnTrue} 
}

function test_ssh_unset {
   ! _sshRaiseConnectionNotSet && pass_test || fail_test 
   ssh_unset 
   _sshRaiseConnectionNotSet 2>&1 | assert_match "ERROR"
}

function ssh_pass_reset {
   # Used to reset the SSHPASS variables.
   # >>> ssh_pass_reset
   SSHPASSNODE=
   SSHPASS=
   SSHPASSPROG=
}

function _sshSetSSHPASS {
   # Sets the SSHPASS environment variable from the config file or by prompting user.
   # >>> _sshSetSSHPASS "ssh_node"
   # ssh_node: SSH user@hostname.
   ${arcRequireBoundVariables}
   debug3 "_sshSetSSHPASS: $*"
   typeset ssh_node 
   ssh_node="${1}"
   [[ "${ssh_node}" == "${SSHPASSNODE:-}" ]] && ${returnTrue} 
   SSHPASS=
   SSHPASSPROG=
   eval "$(ssh_load "${ssh_node}")"
   SSHPASSNODE="${ssh_node}"
   if [[ -n "${node_sshpass:-}" ]]; then
      log_terminal "Using 'sshpass' to connect or perform actions."
      SSHPASS="${node_sshpass}"
      SSHPASSPROG="sshpass -e "
   fi
   ${returnTrue} 
}

function test_sshSetSSHPASS {
   :
}

function _sshLogGlobalConnectionChange {
   # Write an application log level entry anytime the global connection is changed.
   # >>> _sshLogGlobalConnectionChange
   ${arcRequireBoundVariables}
   typeset ssh_connection
   ssh_connection="$(_sshXREF "${1}")"
   if [[ "${ssh_connection}" != "${_g_sshConnection:-"_"}" ]]; then
      if _sshDoesGroupExist "${ssh_connection}"; then
         log_terminal "Setting ssh connection to '${ssh_connection}' group."
      elif _sshDoesNodeExist "${ssh_connection}"; then
         log_terminal "Setting ssh connection to '${ssh_connection}' node."
      elif _sshDoesTagExist "${ssh_connection}"; then
         log_terminal "Setting ssh connection '${ssh_connection}' tag."
      else
         _sshThrowError "Connection not found: $*: _sshLogGlobalConnectionChange"
         ${returnFalse} 
      fi
      # Something changed.
      ${returnTrue} 
   else
      # Nothing changed.
      ${returnFalse} 
   fi
}

function test__sshLogGlobalConnectionChange {
   ssh_add -alias "foo" "foo@bar" && pass_test || fail_test 
   ssh_refresh 
   ssh_unset 
   _sshLogGlobalConnectionChange "foo" 2>&1 && pass_test || fail_test 
   _sshLogGlobalConnectionChange "bar" 2>&1 | assert_match "ERROR"
}

function ssh_return_groups {
   # List the ssh groups.
   # >>> ssh_return_groups
   ${arcRequireBoundVariables}
   config_list_all_objects "ssh_groups" | egrep -v "example" | sed 's/\.cfg//'
   ${returnTrue} 
}

function test_ssh_return_groups {
   ssh_return_groups | assert -l ">0"
}

function ssh_return_nodes_in_group {
   # Return the list of node names in a group.
   # >>> ssh_return_nodes_in_group "ssh_group"
   ${arcRequireBoundVariables}
   debug3 "ssh_return_nodes_in_group: $*"
   typeset ssh_group file_path ssh_connection
   ssh_group="${1}"
   eval "$(config_load_object "ssh_groups" "${ssh_group}.cfg")"
   ${returnTrue} 
}

function ssh_return_tags {
   # List the ssh tags.
   # >>> ssh_return_tags
   ${arcRequireBoundVariables}
   file_list_files "${_sshDir}/tags"
   ${returnTrue} 
}

function test_ssh_return_tags {
   ssh_add -port 22 -alias "foo" -tags "moo" "foo@bar"
   ssh_add -port 22 -alias "fa" -tags "moo" "fa@bin"
   ssh_refresh 
   ssh_return_tags | assert_match "moo"
   ssh_delete "fa"
}

function ssh_return_tags_for_this_node {
   # Return the list of tags associated with the local node.
   # >>> ssh_return_tags_for_this_node
   ${arcRequireBoundVariables}
   eval "$(ssh_load "${arcNode}")"
   echo "${node_tags:-}" | str_split_line -stdin "," | utl_remove_blank_lines -stdin
}

function ssh_is_tag_assigned_to_this_node {
   # Return true if the local node is associated with the given tag. 
   # >>> ssh_is_tag_assigned_to_this_node "tag"
   ${arcRequireBoundVariables}
   typeset tag 
   tag="${1}"
   eval "$(ssh_load "${arcNode}")"
   if (( $(ssh_return_tags_for_this_node | grep "^${tag}$" | wc -l) )); then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test_ssh_is_tag_assigned_to_this_node {
   ssh_delete "${arcNode}"
   ssh_add "${arcNode}" 
   ssh_refresh 
   ! ssh_is_tag_assigned_to_this_node "foo" && pass_test || fail_test "Node should not have any tags associated with it."
   ssh_add -tags "foo,bar" "${arcNode}"
   ssh_refresh 
   ssh_is_tag_assigned_to_this_node "foo" && pass_test || fail_test "'foo' tag exists, returns true."
   ssh_is_tag_assigned_to_this_node "bar" && pass_test || fail_test "'bar' tag exists, returns true."
   ! ssh_is_tag_assigned_to_this_node "b" && pass_test || fail_test "Partial tag returns false."
   ssh_delete "${arcNode}"
   _sshAddLocalHost
}

function ssh_return_nodes_with_tag {
   # Return the list of nodes associated with a tag.
   # >>> ssh_return_nodes_with_tag "ssh_tag"
   ${arcRequireBoundVariables}
   debug3 "ssh_return_nodes_with_tag: $*"
   typeset ssh_tag file_path ssh_connection
   ssh_tag="${1}"
   if [[ -f "${_sshDir}/tags/${ssh_tag}" ]]; then
      cat "${_sshDir}/tags/${ssh_tag}"
   fi
   ${returnTrue} 
}

function test_ssh_return_nodes_with_tag {
   ssh_add -port 22 -alias "foo" -tags "moo" "foo@bar"
   ssh_add -port 22 -alias "fa" -tags "moo" "fa@bin"
   ssh_refresh 
   ssh_return_nodes_with_tag "moo" | egrep "foo@bar|fa@bin" | assert -l 2
   ssh_delete "foo"
   ssh_delete "fa"
   ssh_refresh 
}

function _sshDoesNodeOrGroupExist {
   # Return true if item is a node or group.
   # >>> _sshDoesNodeOrGroupExist "ssh_connection"
   ${arcRequireBoundVariables}
   debug3 "_sshDoesNodeOrGroupExist: $*"
   typeset ssh_connection 
   ssh_connection="$(_sshXREF "${1}")"
   if _sshDoesGroupExist "${ssh_connection}" || _sshDoesNodeExist "${ssh_connection}"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _sshDeleteSSHConnectionLookups {
   # Delete loaded SSH configuration for nodes.
   # >>> _sshDeleteSSHConnectionLookups
   debug3 "_sshDeleteSSHConnectionLookups: $*"
   find "${_sshDir}/nodes" -type f -exec rm {} \;
   find "${_sshDir}/aliases" -type f -exec rm {} \;
   find "${_sshDir}/tags" -type f -exec rm {} \;
   ${returnTrue} 
}

function test__sshDeleteSSHConnectionLookups {
   _sshDeleteSSHConnectionLookups && pass_test || fail_test 
   ssh_refresh && pass_test || fail_test 
}

function _sshDeleteSSHConnectionGroupLookups {
   # Delete loaded SSH configuration for groups.
   # >>> _sshDeleteSSHConnectionGroupLookups
   find "${_sshDir}/groups" -type f -exec rm {} \;
   ${returnTrue} 
}

function _sshAddLocalHost {
   # Create a reference for the local node if it doesn't exist..
   # >>> _sshAddLocalHost
   ${arcRequireBoundVariables}
   if ! _sshDoesNodeExist "${arcNode}"; then
      ssh_add "${arcNode}"
   fi
   ${returnTrue} 
}

function test__sshAddLocalHost {
   rm "${arcGlobalHome}/config/ssh_connections/${arcNode}.cfg" && pass_test || fail_test 
   _sshAddLocalHost && pass_test || fail_test 
   echo "${arcGlobalHome}/config/ssh_connections/${arcNode}.cfg" | assert -f
   ssh_refresh && pass_test || fail_test 
}

function _sshDoesNodeExist {
   # Return true if the "node_name" exists.
   # >>> _sshDoesNodeExist "node_name"
   ${arcRequireBoundVariables}
   debug3 "_sshDoesNodeExist: $*"
   typeset node_name
   node_name="${1}"
   if config_does_object_exist "ssh_connections" "${node_name}.cfg"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test__sshDoesNodeExist {
   ! _sshDoesNodeExist "foo" && pass_test || fail_test 
   _sshDoesNodeExist "test@$(hostname)" && pass_test || fail_test 
   ! _sshDoesNodeExist "test" && pass_test || fail_test "Should not work with aliases."
}

function _sshDoesTagExist {
   # Return true if the "ssh_tag" exists.
   # >>> _sshDoesTagExist "ssh_tag"
   ${arcRequireBoundVariables}
   typeset ssh_tag 
   ssh_tag="${1}"
   if [[ -f "${_sshDir}/tags/${ssh_tag}" ]]; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _sshDoesGroupExist {
   # Return true if the group exists.
   # >>> _sshDoesGroupExist "ssh_group"
   ${arcRequireBoundVariables}
   typeset ssh_group
   debug3 "_sshDoesGroupExist: $*"
   ssh_group="${1}"
   if config_does_object_exist "ssh_groups" "${ssh_group}.cfg"; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test__sshDoesGroupExist {
   ! _sshDoesGroupExist "foo" && pass_test || fail_test 
   _sshDoesGroupExist "mygroup" && pass_test || fail_test 
}

function _sshRaiseIsNotANodeOrNodeAlias {
   # Throw error and return true if 'ssh_node' is not a user@hostname or node alias.
   # >>> _sshRaiseIsNotANodeOrNodeAlias "ssh_node_or_alias"
   # ssh_node_or_alias: SSH user@hostname or alias.
   ${arcRequireBoundVariables}
   typeset ssh_node_or_alias
   ssh_node_or_alias="${1}"
   if _sshDoesGroupExist "${ssh_node_or_alias}" || _sshDoesTagExist "${ssh_node_or_alias}"; then
      _sshThrowError "${ssh_node_or_alias} is not a node or node alias: $*: _sshRaiseIsNotANodeOrNodeAlias"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _sshRaiseIsGroup {
   # Throw error and return true when 'ssh_group' is a group.
   # >>> _sshRaiseIsGroup "ssh_group"
   ${arcRequireBoundVariables}
   typeset ssh_group 
   ssh_group="${1}"
   if _sshDoesGroupExist "${ssh_group}"; then
      _sshThrowError "'${ssh_group}' is a group: $*: _sshRaiseIsGroup"
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test__sshRaiseIsGroup {
   ! _sshRaiseIsGroup "foo" && pass_test || fail_test 
   _sshRaiseIsGroup "mygroup" 2>&1 | assert_match "ERROR"
}

function _sshRaiseIsNotGroup {
   # Throw error and return true when 'ssh_group' is not a group.
   # >>> _sshRaiseIsNotGroup "ssh_group"
   ${arcRequireBoundVariables}
   typeset ssh_group 
   ssh_group="${1}"
   if ! _sshDoesGroupExist "${ssh_group}"; then
      _sshThrowError "'${ssh_group}' is not a group: $*: _sshRaiseIsNotGroup"
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test__sshRaiseIsNotGroup {
   ! _sshRaiseIsNotGroup "mygroup" && pass_test || fail_test 
   _sshRaiseIsNotGroup "foo" 2>&1 | assert_match "ERROR"
}

function _sshListNodes {
   # Return a list of the ssh nodes found in the "ssh_connections" directory.
   # >>> _sshListNodes
   ${arcRequireBoundVariables}
   config_list_all_objects "ssh_connections" | egrep -v "example" | sed 's/\.cfg//'
   ${returnTrue} 
}

function test__sshListNodes {
   _sshListNodes | assert -l ">0"
   _sshListNodes 1> /dev/null && pass_test || fail_test 
}

function ssh_load {
   # Load the attributes for an ssh node.
   # >>> eval "$(ssh_load "node")"
   ${arcRequireBoundVariables}
   typeset node
   node="$(_sshXREF "${1}")" || ${returnFalse} 
   echo "$(config_load_object "ssh_connections" "${node}.cfg")"
   ${returnTrue} 
}

function test_ssh_load {
   eval "$(ssh_load "test")" 
   echo "${node_alias}" | assert "test"
   eval "$(ssh_load "dev")" 
   echo "${node_alias}" | assert "dev"
}

function _sshRaiseDuplicateAlias {
   # Throw error and return true if the alias has already been used.
   # >>> _sshRaiseDuplicateAlias "node_alias"
   ${arcRequireBoundVariables}
   typeset node_alias
   node_alias="${1:-}"
   if [[ -f "${_sshDir}/aliases/${1}" && -n "${node_alias:-}" ]]; then
      _sshThrowError "Alias is already in use: $*: _sshRaiseNameIsAlreadyBeingUsed"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _sshBracketizeList {
   # Takes "foo,bar" and turns it into "[foo][bar]".
   # >>> _sshBracketizeList "list"
   typeset x i
   x="${1:-}"
   if [[ -n "${x:-}" ]]; then
      while read i; do
         printf "[%s]" "${i}"
      done < <(echo "${x}" | str_split_line -stdin ",")
   else
      printf "[]"
   fi
}

function _sshXREF {
   # Returns input unless the input is an alias, in which case it returns the user@host string.
   # >>> _sshXREF "ssh_connection"
   ${arcRequireBoundVariables}
   debug3 "_sshXREF: $*"
   typeset ssh_connection
   ssh_connection="${1}"
   if [[ -f "${_sshDir}/groups/${1}" ]]; then
      echo "${ssh_connection}"
      ${returnTrue} 
   elif [[ -f "${_sshDir}/tags/${ssh_connection}" ]]; then
      echo "${ssh_connection}"
      ${returnTrue} 
   elif [[ -f "${_sshDir}/aliases/${ssh_connection}" ]]; then
      cat "${_sshDir}/aliases/${ssh_connection}"
      ${returnTrue} 
   elif [[ -f "${_sshDir}/nodes/${ssh_connection}" ]]; then
      echo "${ssh_connection}"
      ${returnTrue} 
   else
      _sshThrowError "Connection not found: '$*': _sshXREF"
      ${returnFalse} 
   fi
}

function _sshDoesAliasExistStrict {
   # Return true if alias exists. Must provide alias and not node.
   # >>> _sshDoesAliasExistStrict "alias"
   ${arcRequireBoundVariables}
   typeset alias 
   alias="${1}"
   if [[ -f "${_sshDir}/aliases/${alias}" ]]; then
      ${returnTrue} 
   else
     ${returnFalse} 
   fi
}

function _sshDoesNodeExistStrict {
   # Return true if node exists. Must provide node and not alias.
   # >>> _sshDoesNodeExistStrict "node"
   ${arcRequireBoundVariables}
   typeset node 
   node="${1}"
   if _sshDoesNodeExist "${node}"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _sshIsConnectionSet {
   # Returns true if the ssh connection is set.
   # >>> _sshIsConnectionSet
   ${arcRequireBoundVariables}
   if [[ -n "${_g_sshConnection:-}" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function _sshThrowError {
   # Returns an error message to standard error.
   # >>> _sshThrowError "error"
   # error: Error message text.
   ${arcRequireBoundVariables}
   throw_error "arcshell_ssh_connections.sh" "${1}"
}

