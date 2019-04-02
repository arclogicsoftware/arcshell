
# module_name="Contact Groups"
# module_about="Manages group membership and the rules used to send messages to the group."
# module_version=1
# module_image="user-6.png"
# copyright_notice="Copyright 2019 Arclogic Software"

mkdir -p "${arcGlobalHome}/config/contact_groups"

_contactgroupsHome="${arcTmpDir}/_arcshell_contact_groups"

function __readmeContactGroups {
   cat <<EOF
# Contact Groups
**Manages group membership and the rules used to send messages to the group.**

Contact groups are used to route messages to the right people, at the right time, using the configured means.

In ArcShell messages can be sent to one or more specific contact groups but ArcShell will route messages to any available contact group if one is not specified.

You can use contact groups to implement automated on-call rotations, message buffering, and define windows in which one contact method is preferred over another.

Each group is configured using an ArcShell configuration file.

The delivered configuration files are in \`\`\`\${arcHome}/config/contact_groups\`\`\`.

Configure a contact group by adding a file of the same name to \`\`\`\${arcGlobalHome}/config/contact_groups\`\`\` or \`\`\`\${arcUserHome}/config/contact_groups\`\`\` and modifying the desired values. 

New contact groups can be created by adding a file to one of these directories.

ArcShell loads contact groups in top down order. Delivered, global, then user. All identified files will be loaded when a contact group is used in the code base.

**Example of a contact group configuration file.** 

Contact groups configuration files are loaded as shell scripts. You can use shell to conditionally set the values in these files.

\`\`\`
# \${arcHome}/config/contact_groups/admins.cfg
$(cat ${arcHome}/config/contact_groups/admins.cfg)
\`\`\`
EOF
}

function __setupContactGroups {
   # Run setup for contact groups.
   # >>> __setupContactGroups 
   if ! [[ -f "${arcGlobalHome}/config/contact_groups/admins.cfg" ]]; then
      cp "${arcHome}/config/contact_groups/admins.cfg" "${arcGlobalHome}/config/contact_groups/"
   fi
}

function test_function_setup {
   (
   cat <<EOF
   group_enabled=1
   group_emails="foo@bar.com"
   group_default_group=1
EOF
   ) > "${arcHome}/config/contact_groups/foo.cfg" 
   (
   cat <<EOF
   group_enabled=0
   group_default_group=0
EOF
   ) > "${arcHome}/config/contact_groups/bar.cfg" 
}

function contact_group_load {
   # Loads a group into the current shell.
   # >>> eval "$(contact_group_load 'group_name')"
   ${arcRequireBoundVariables}
   utl_raise_invalid_option "contact_group_load" "(( $# == 1 ))" "$*" && ${returnFalse} 
   debug3 "contact_group_load: $*"
   typeset group_name 
   group_name="${1}"
   _configRaiseObjectNotFound "contact_groups" "${group_name}.cfg" && ${returnFalse} 
   echo "$(config_load_all_objects "contact_groups" "${group_name}.cfg")"
}

function test_contact_group_load {
   typeset group_emails
   group_emails= 
   eval "$(contact_group_load "foo")"
   echo "${group_emails}" | assert "foo@bar.com"
}

function _groupsRaiseGroupNotFound {
   # Return an error and true if the group is not found.
   # >>> _groupsRaiseGroupNotFound "group_name"
   ${arcRequireBoundVariables}
   typeset group_name
   group_name="${1}"
   if _configRaiseObjectNotFound "contact_groups" "${group_name}.cfg"; then
      ${returnTrue} 
   else 
      ${returnFalse} 
   fi
}

function test__groupsRaiseGroupNotFound {
   _groupsRaiseGroupNotFound "barX" 2>&1 | assert_match "ERROR"
   ! _groupsRaiseGroupNotFound "foo" && pass_test || fail_test 
}

function contact_group_exists {
   # Return true if the contact group exists.
   # >>> contact_group_exists "group_name"
   ${arcRequireBoundVariables}
   utl_raise_invalid_option "contact_group_exists" "(( $# == 1 ))" "$*" && ${returnFalse} 
   typeset group_name 
   group_name="${1}"
   if config_does_object_exist "contact_groups" "${group_name}.cfg"; then
      ${returnTrue}
   else
      ${returnFalse} 
   fi
}

function contact_group_is_enabled {
   # Returns true if group is "enabled" and not "disabled".
   # >>>  contact_group_is_enabled "group_name"
   ${arcRequireBoundVariables}
   utl_raise_invalid_option "contact_group_is_enabled" "(( $# == 1 ))" "$*" && ${returnFalse} 
   debug3 "contact_group_is_enabled: $*"
   typeset group_name group_disabled group_enabled
   group_name="${1}"
   _groupsRaiseGroupNotFound "${group_name}" && ${returnFalse} 
   eval "$(contact_group_load "${group_name}")"
   if is_truthy "${group_disabled:-0}"; then
      ${returnFalse} 
   elif is_truthy "${group_enabled:-1}"; then
      ${returnTrue} 
   else 
      ${returnFalse} 
   fi
}

function test_contact_group_is_enabled {
   contact_group_is_enabled "foo" && pass_test || fail_test
   ! contact_group_is_enabled "bar" && pass_test || fail_test 
}

function _groupsGetDefaultGroupCount {
   # Return the number of default groups defined.
   # >>> _groupsGetDefaultGroupCount
   ${arcRequireBoundVariables}
   contact_groups_list_default | num_line_count
} 

function test__groupsGetDefaultGroupCount {
   _groupsGetDefaultGroupCount | assert ">=2"
}

function contact_groups_enabled_count {
   # Return the number of enabled contact groups.
   # >>> contact_groups_enabled_count
   contact_groups_list_enabled | num_line_count
}

function contact_groups_list {
   # Return the list of all groups.
   # >>> contact_groups_list [-l|-a]
   # -l: Long list. Include file path to the groups configuration file.
   # -a: All. List every configuration file for every group.
   ${arcRequireBoundVariables}
   if (( $# == 0 )); then
      config_list_all_objects $* "contact_groups" | sed 's/\.cfg$//'
   else
      config_list_all_objects $* "contact_groups"
   fi
}

function test_contact_groups_list {
   contact_groups_list | egrep "bar|foo" | assert -l ">=2"
   contact_groups_list | assert -l ">=2"
}

function contact_groups_list_enabled {
   # Return the list of groups which are currently enabled.
   # >>> contact_groups_list_enabled
   ${arcRequireBoundVariables}
   typeset group_name 
   while read group_name; do
      contact_group_is_enabled "${group_name}" && echo "${group_name}"
   done < <(contact_groups_list)
}

function contact_groups_list_default {
   # Return a list of the default groups, they are not necessarily enabled.
   # >>> contact_groups_list_default
   ${arcRequireBoundVariables}
   debug3 "contact_groups_list_default: $*"
   typeset group_name group_default_group
   while read group_name; do
      group_default_group=
      eval "$(contact_group_load "${group_name}")"
      if is_truthy "${group_default_group:-1}"; then
         echo "${group_name}"
      fi
   done < <(contact_groups_list)
}

function test_contact_groups_list_default {
   contact_groups_list_default | assert -l ">=2"
}

function contact_group_delete {
   # Delete a contact group.
   # > Make sure you run 'contact_groups_refesh' after deleting one or more groups.
   # >>> contact_group_delete "group_name"
   ${arcRequireBoundVariables}
   typeset group_name 
   utl_raise_invalid_option "contact_group_delete" "(( $# == 1 ))" && ${returnFalse} 
   group_name="${1}"
   config_delete_object "contact_groups" "${group_name}.cfg"
}

function test_file_teardown {
   contact_group_delete "foo"
   contact_group_delete "bar"
}
