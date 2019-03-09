
# sudo.sh
# ```Basic Linux administrative functions.```
# Copyright 2019 Arclogic Software
# Version 1

. "${HOME}/.arcshell"

function __setupSudo {
   # app_build "sudo"
   :
}

function sudo_update {
   # Fetch the list of available updates.
   # >>> sudo_update
   sudo apt-get update        
}

function test_sudo_update {
   sudo_update && pass_test || fail_test 
}

function sudo_upgrade {
   # Update current packages.
   # >>> sudo_upgrade
   sudo apt-get upgrade        
}

function test_sudo_update {
   sudo_upgrade && pass_test || fail_test 
}

function sudo_dist_upgrade {
   # Install new packages.
   # >>> sudo_dist_upgrade
   sudo apt-get dist-upgrade
}

function test_sudo_dist_upgrade {
   sudo_dist_upgrade && pass_test || fail_test 
}

function sudo_update_all {
   # Updates and installs current packages as well as installs new ones.
   # >>> sudo_update_all
   sudo_update || ${returnFalse}       
   sudo_upgrade || ${returnFalse} 
   sudo_dist_upgrade || ${returnFalse} 
   ${returnTrue} 
}

function test_sudo_update_all {
   sudo_update_all && ${returnTrue} 
}

function sudo_create_user {
   # Create a user and home directory if the user does not already exist.
   # >>> sudo_create_user "user" ["pass"] ["shell"]
   ${arcRequireBoundVariables}
   debug1 "$*: sudo_create_user"
   utl_raise_invalid_option "sudo_create_user" "(( $# >= 1 && $# <= 3 ))" && ${returnFalse} 
   typeset user pass shell 
   user="${1}"
   shift 
   if (( $# == 2 )); then
      pass="${1}"
      shell="${2}"
   elif (( $# == 1 )); then
      if str_instr "/" "${1:-}" 1>/dev/null; then
         shell="${1}"
      else
         pass="${1}"
      fi
   fi
   if ! sudo_does_user_exist "${1}"; then
      if [[ -n "${shell:-}" ]]; then
         shell="-s ${shell} " 
      fi
      # ! sudo su -c "useradd -m ${user} ${shell:-}" && ${returnFalse} 
      ! sudo useradd -m ${shell:-} ${user} && ${returnFalse} 
      if [[ -n "${pass:-}" ]]; then
         sudo_set_pass "${user}" "${pass}" 
      fi
   fi
   ${returnTrue}  
}

function test_sudo_create_user {
   sudo_create_user 2>&1 | assert_match "ERROR"
   sudo_delete_user "foo" && pass_test || fail_test 
   ! sudo_does_user_exist "foo" && pass_test || fail_test 
   sudo_create_user "foo" && pass_test || fail_test 
   sudo_does_user_exist "foo" && pass_test || fail_test 
   sudo_create_user "foo" && pass_test || fail_test 
}

function sudo_delete_user {
   # Delete a Linux/Unix user account and home directory.
   # >>> sudo_delete_user "user"
   ${arcRequireBoundVariables}
   debug1 "$*: sudo_delete_user"
   utl_raise_invalid_option "sudo_delete_user" "(( $# == 1 ))" && ${returnFalse} 
   if sudo_does_user_exist "${1}" && [[ "${1}" != "root" ]]; then
      ! sudo userdel -r ${1} 
   fi
   ! sudo_does_user_exist "${1}" && ${returnTrue} 
   ${returnFalse} 
}

function test_sudo_delete_user {
   :
}

function sudo_does_user_exist {
   # Return true if user exists.
   # sudo_does_user_exist "user"
   ${arcRequireBoundVariables}
   debug2 "$*: sudo_does_user_exist"
   utl_raise_invalid_option "sudo_does_user_exist" "(( $# == 1 ))" && ${returnFalse} 
   if grep "^${1}:" "/etc/passwd" 1>/dev/null; then
      ${returnTrue}
   else
      ${returnFalse} 
   fi
}

function test_sudo_does_user_exist {
   sudo_does_user_exist "root" && pass_test || fail_test 
   sudo_delete_user "foo" && pass_test || fail_test 
   sudo_does_user_exist "foo" && fail_test || pass_test 
   sudo_does_user_exist 2>&1 | assert_match "ERROR"  
}

function sudo_set_pass {
   # Set the password for a user. Should be changed right away, this is only for testing.
   # sudo_set_pass "user" "pass"
   ${arcRequireBoundVariables}
   debug2 "********: sudo_set_pass"
   if [[ "${arcOSType}" == "SUNOS" ]]; then
      _throwSSHError "This command is not supported on Solaris: ********: sudo_set_pass"
      ${returnFalse} 
   fi
   if echo "${1}:${2}" | sudo chpasswd; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test_sudo_set_pass {
   sudo_create_user "foo" && pass_test || fail_test 
   sudo_set_pass "foo" "bar" && pass_test || fail_test  
   sudo_delete_user "foo" 
}

function _sudoThrowError {
   # Return error message to standard error.
   # >>> _sudoThrowError "error_message"
   throw_error "arcshell_nix.sh" "${1}"
}

