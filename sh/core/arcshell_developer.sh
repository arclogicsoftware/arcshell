
function _readmeArcShellDeveloper {
  cat <<EOF
> The third version is the first version that doesn't suck. -Mike Simpson

# ArcShell Developer

This module contains things you might need to get up and running with ArcShell core development.
EOF
}

function arcdev_setup_env {
  # This function will create all of the required user accounts to support unit testing ArcShell.
  # >>> arcdev_setup_env
  ${arcRequireBoundVariables}
  typeset pass_initial pass_confirm user_name
  . ${arcHome}/app/sudo/sudo.sh 
  printf "Enter password for development user accounts: "
  read pass_initial
  printf "Confirm: "
  read pass_confirm
  if [[ "${pass_initial}" != "${pass_confirm}" ]]; then
    throw_error "Passwords didn't match!"
    ${returnFalse} 
  fi
  echo "${pass_initial}" > "${arcTmpDir}/pass_initial.txt"
  chmod 600 "${arcTmpDir}/pass_initial.txt"
  ssh_delete_all_connections
  # 'dev' user needs a non Bash or Korn default shell.
  for user_name in "dev"; do
    sudo_delete_user "${user_name}"
    sudo_create_user "${user_name}" "${pass_initial}" "/bin/sh"
  done 
  for user_name in "test" "prod1" "prod2"; do
    sudo_delete_user "${user_name}"
    sudo_create_user "${user_name}" "${pass_initial}" "/bin/bash"
  done 
  ssh_add -alias "dev" -tags "web,app,sh" "dev@$(hostname)"
  ssh_add -alias "test" -tags "web,app,bash" "test@$(hostname)"
  ssh_add -alias "prod1" -tags "web,prod,bash" "prod1@$(hostname)" 
  ssh_add -alias "prod2" -tags "app,prod,bash" "prod2@$(hostname)"
  (
  cat <<'EOF'
  echo "dev"
  echo "test"
  echo "web"
EOF
  ) > "${arcGlobalHome}/config/ssh_groups/mygroup"
  ssh_refresh 
  ssh_set "test"
  ssh_check -fix
  ssh_send_key
  ssh_unset 
  ${returnTrue} 
}