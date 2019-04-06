
# module_name="ArcShell"
# module_about="Contains functions to manage local and remote ArcShell nodes."
# module_version=1
# module_image="network.png"
# copyright_notice="Copyright 2019 Arclogic Software"

_arcDir="${arcTmpDir}/_arcshell_arc"
mkdir -p "${_arcDir}"

_g_arcGlobalPackagesDir="${arcGlobalHome}/config/packages"
_g_arcLocalPackagesDir="${arcUserHome}/config/packages"

function __readmeArcShell {
   cat <<EOF
> Working software is the primary measure of progress. -- Agile Manifesto

# ArcShell

**Contains functions to manage local and remote ArcShell nodes.**

This module provides users with the ability to install, package, update, uninstall, and run commands on other ArcShell nodes over SSH. 

There are other helpful commands which can be used when building your own modules for ArcShell. 

EOF
}

function __setupArcShell {
   # Unsuspend the daemon anytime you run setup.
   ! flag_exists "daemon_suspended" && flag_set "daemon_suspended" "no"
}

function __configArcShell {
   # Create an empty global arcshell.cfg file if it does not exist.
   if [[ ! -f "${arcGlobalHome}/config/arcshell/arcshell.cfg" ]]; then
      touch "${arcGlobalHome}/config/arcshell/arcshell.cfg"
      chmod 600 "${arcGlobalHome}/config/arcshell/arcshell.cfg"
   fi
   # Create an empty global setup.cfg file if it does not exist.
   if [[ ! -f "${arcGlobalHome}/config/arcshell/setup.cfg" ]]; then
      touch "${arcGlobalHome}/config/arcshell/setup.cfg"
      chmod 600 "${arcGlobalHome}/config/arcshell/setup.cfg"
   fi
}

function __exampleArcShell {
   # Package the current ArcShell home.
   arc_pkg 
   # Set the SSH connection to 'tst'. 'tst' is already configured as an SSH connection.
   ssh_set "tst"
   # Setup ArcShell on 'tst' using the package we just created. 
   arc_install -force
   # Assume some change has been made. Re-package the current ArcShell home.
   arc_pkg 
   # Update the remote ArcShell home on 'tst' using the new package.
   arc_update 
   # Assume another change has been made.
   # Use rsync to sync the current ArcShell home to 'tst' home. This skips the packaging step.
   arc_sync
   # Remove ArcShell from the report 'tst' home/
   arc_uninstall
}

function arc_update_from_github {
   # Updates the current ArcShell home from GitHub.
   # >>> arc_update_from_github [-delete,-d] ["url"]
   # -delete: Delete files from local node which don't exist on the source.
   ${arcRequireBoundVariables}
   typeset delete_option download_url tmpDir starting_dir
   delete_option=0
   download_url="https://github.com/arclogicsoftware/arcshell/archive/master.zip"
   while (( $# > 0)); do
      case "${1}" in
         "-delete"|"-d") delete_option=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "arc_update_from_github" "(( $# <= 1 ))" "$*" && ${returnFalse}
   (( $# == 1 )) && download_url="${1}"
   boot_raise_program_not_found "wget" && ${returnFalse} 
   boot_raise_program_not_found "unzip" && ${returnFalse} 
   tmpDir="$(mktempd)"
   starting_dir="$(pwd)"
   cd "${tmpDir}" || ${returnFalse} 
   wget "${download_url}" 
   unzip "${tmpDir}/"*".zip"
   if (( $(file_list_dirs "${tmpDir}" | wc -l) != 1 )); then
      log_error -2 -logkey "arcshell" "Downloaded file contained more than one root directory: $*: _arcDownloadAndUpdateFromGitHubMasterZipFile"
      ${returnFalse} 
   fi
   new_directory="$(file_list_dirs "${tmpDir}")"
   cd "${new_directory}" || ${returnFalse} 
   find "${tmpDir}/${new_directory}" -type f -name "*.sh" -exec chmod 700 {} \;
   #cd "${arcHome}" || ${returnFalse} 
   ./arcshell_update.sh 
   cd "${starting_dir}"
   rm -rf "${tmpDir}"
   ${returnTrue} 
}

function arc_menu {
   # Runs the ArcShell main menu.
   # >>> arc_menu
   ${arcRequireBoundVariables}
   typeset f o

   menu_create "arcshell_help_submenu" "Help"
   while read f; do
      menu_add_command "${f} -aa | more; read" "${f}" 
   done < <(utl_return_matching_loaded_functions "[a-z].*_help$")
   menu_add_command "clear" "Clear Screen"

   menu_create "arcshell_show_config_submenu" "Configuration Object Details"
   while read o; do 
      menu_add_command "config_show_config "${o}"" "${o}"
   done < <(config_list_all_object_types)

   menu_create "arcshell_daemon_submenu" "Daemon"
   menu_add_command "arcshell.sh daemon status" "Status"
   menu_add_command "nohup arcshell.sh daemon start &" "Start"
   menu_add_command "nohup arcshell.sh daemon restart &" "Restart"
   menu_add_command "arcshell.sh daemon stop" "Stop"
   menu_add_command "arcshell.sh daemon kill" "Kill"

   menu_create "arc_menu" "ArcShell" 
   menu_add_menu "arcshell_help_submenu" "Help"
   menu_add_menu "arcshell_daemon_submenu" "Daemon"
   menu_add_menu "arcshell_show_config_submenu" "Configuration Object Details"
   menu_add_command "${arcHome}/arcshell_setup.sh" "Run ArcShell setup." 
   menu_add_command "clear" "Clear"

   menu_show "arc_menu"
   ${returnTrue} 
}

function _arcReturnArcShellProcessCount {
   # Return the number of processes initiated from ArcShell.
   # >>> _arcReturnArcShellProcessCount
   ${arcRequireBoundVariables}
   typeset process_count 
   if [[ "${1:-}" == "-d" ]]; then
      ps -ef | grep "${LOGNAME}.*arcshell.sh" | egrep -v "grep" 3>&1 1>&2 2>&3
   fi
   process_count=$(ps -ef | grep "${LOGNAME}.*arcshell.sh" | egrep -v "grep" | wc -l)
   if (( ${process_count} )); then
      echo ${process_count} && ${returnTrue} 
   else
      echo ${process_count} && ${returnFalse} 
   fi
}

function test__arcReturnArcShellProcessCount {
   _arcReturnArcShellProcessCount | assert ">=0"
   if (( $(_arcReturnArcShellProcessCount) )); then
      _arcReturnArcShellProcessCount 1> /dev/null && pass_test || fail_test 
   else
      ! _arcReturnArcShellProcessCount 1> /dev/null && pass_test || fail_test 
   fi
}

function arc_version {
   # Returns the current version of ArcShell.
   # >>> arc_version [-n]
   # -n: Returns the version as a real number instead of a string.
   ${arcRequireBoundVariables}
   if [[ "${1:-}" == "-n" ]]; then
      cat "${arcHome}/resource/version.txt" | sed 's/\.//g'
   else
      cat "${arcHome}/resource/version.txt" 
   fi
}

# function arc_download {
#    # Download the latest ArcShell 'tar' file from a download link using wget.
#    # >>> arc_download ["download_url"]
#    # download_url: URL to download an ArcShell tar.gz file.
#    ${arcRequireBoundVariables}
#    typeset pwd0 download_url
#    download_url="${1:-${arcshell_download_url:-}}"
#    utl_raise_empty_var "download_url is not set. Please provide a URL." "${download_url}" && ${returnFalse} 
#    find "${arcUserHome}/config/packages" -type f -name "arcshell.tar.gz" -exec rm {} \;
#    pwd0="$(pwd)"
#    cd "${arcUserHome}/config/packages" || ${returnFalse} 
#    wget -q -O "./arcshell.tar.gz" "${download_url}"
#    cd "${pwd0}"
#    pkg_unset 
#    if [[ -f "${arcUserHome}/config/packages/arcshell.tar.gz" ]]; then
#       log_terminal "ArcShell successfully downloaded the file to '${arcUserHome}/config/packages/arcshell.tar.gz'."
#       pkg_set "${arcUserHome}/config/packages/arcshell.tar.gz"
#       ${returnTrue} 
#    else
#       log_error "Failed to download ArcShell from '${download_url}'."
#       ${returnFalse} 
#    fi
# }

function arc_install {
   # Install ArcShell on one or more remote nodes over SSH.
   # >>> arc_install [-force,-f] [-arcshell_home,-a "X"] [-ssh "X"] ["package_path"]
   # -force: Install ArcShell even if it is already installed.
   # -arcshell_home: Directory which will be the "${arcHome}" on the node.
   # -ssh: SSH user@hostname, alias, tag, or group.
   # package_path: Path to ArcShell package file. Not required if the working package file is set.
   ${arcRequireBoundVariables}
   debug3 "arc_install: $*"
   log_boring -logkey "arcshell" -tags "arc_install" "arc_install: $*"
   typeset force_option arcshell_home ssh_connection package_path errors
   force_option=0
   arcshell_home="\${HOME}/app/arcshell"
   ssh_connection="${_g_sshConnection:-}"
   package_path="${_g_pkgWorkingFile:-}"
   errors=0
   while (( $# > 0)); do
      case "${1}" in
          "-force"|"-f") force_option=1 ;;
         "-arcshell_home"|"-a") shift; arcshell_home="${1}" ;;
         "-ssh") shift; ssh_connection="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "arc_install" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   (( $# > 0 )) && package_path="${1}"
   file_raise_file_not_found "${package_path}" && ${returnFalse} 
   utl_raise_empty_var "SSH connection is not set. Use -ssh option." "${ssh_connection}" && ${returnFalse} 
   echo ""
   echo "You are about to install '${package_path}' package to '${ssh_connection}'."
   echo ""
   utl_confirm || ${returnFalse} 
   while read ssh_node; do
      if ! _arcInstall ${force_option} "${arcshell_home}" "${ssh_node}" "${package_path}" < /dev/null; then
         ((errors=errors+1))
      fi
   done < <(_sshListMembers "${ssh_connection}")
   if (( ${errors} )); then
      ${returnFalse} 
   else
      ${returnTrue} 
   fi
}

function _arcInstall {
   # Remotely install ArcShell on a node from a package over an SSH connection.
   # >>> _arcInstall force_option arcshell_home ssh_node package_path
   # force_option: 0 or 1. Install ArcShell even if it is already installed when 1.
   # arcshell_home: Directory which will be the "${arcHome}" on the node.
   # ssh_node: SSH user@hostname.
   # package_path: Path to ArcShell package file.
   ${arcRequireBoundVariables}
   debug3 "_arcInstall: $*"
   utl_raise_invalid_option "_arcInstall" "(( $# == 4 ))" "$*" && ${returnFalse} 
   typeset force_option arcshell_home ssh_node package_path  load_arcshell
   force_option="${1}"
   arcshell_home="${2}"
   ssh_node="${3}"
   package_path="${4}"
   _sshRaiseIsNotANodeOrNodeAlias "${ssh_node}" && ${returnFalse} 
   ! _pkgMountAsDirectory \
      ${force_option} \
      "${ssh_node}" \
      "${package_path}" \
      "${arcshell_home}" && \
      ${returnFalse}
   log_terminal "Package mounted to '${arcshell_home}'. Executing 'arcshell_setup.sh'."
   ! _sshRunCommandOnTarget \
      ${load_arcshell:-0} \
      "${ssh_node}" \
      "${arcshell_home}/arcshell_setup.sh" && \
      ${returnFalse} 
   log_terminal "Deploy to '${ssh_node}' complete."
   ${returnTrue} 
}

function _arcUpdateFromGitHubZip {
   #
   # >>> _arcUpdateFromZip "zip_file_path"
   ${arcRequireBoundVariables}
   typeset zip_file_path
   boot_raise_program_not_found "unzip" && ${returnFalse} 
   zip_file_path="${1}"
   file_raise_file_not_found "${zip_file_path}" && ${returnFalse} 

}

function arc_update {
   # Update remote or local ArcShell installation using an ArcShell package file.
   # >>> arc_update [-ssh "X"] ["package_path"]
   # -ssh: SSH user@hostname, alias, tag, or group.
   # package_path: Path to ArcShell package file. Not required if the working package file is set.
   ${arcRequireBoundVariables}
   debug3 "arc_update: $*"
   typeset ssh_connection package_path stage_dir delete errors
   ssh_connection="${_g_sshConnection}"
   package_path="${_g_pkgWorkingFile:-}"
   stage_dir=
   errors=0
   while (( $# > 0)); do
      case "${1}" in
         "-ssh") shift; ssh_connection="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_empty_var "SSH connection is not set. Use -ssh option." "${ssh_connection}" && ${returnFalse} 
   utl_raise_invalid_option "arc_update" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   (( $# > 0 )) && package_path="${1}"
   file_raise_file_not_found "${package_path}" && ${returnFalse} 
   echo ""
   echo "This will update '${ssh_connection}' using '${package_path}'."
   echo ""
   utl_confirm || ${returnFalse} 
   while read ssh_node; do
      if ! _arcUpdate "${ssh_node}" "${package_path}"; then
         ((errors=errors+1))
      fi
   done < <(_sshListMembers "${ssh_connection}")
   if (( ${errors} )); then
      ${returnFalse} 
   else
      ${returnTrue} 
   fi
}

function _arcUpdate {
   # Update remote or local ArcShell installation using an ArcShell package file.
   # >>> _arcUpdate "ssh_node" "package_path"
   ${arcRequireBoundVariables}
   debug3 "_arcUpdate: $*"
   typeset package_path stage_dir delete ssh_connection force_option load_arcshell 
   utl_raise_invalid_option "_arcUpdate" "(( $# == 2 ))" "$*" && ${returnFalse} 
   ssh_node="${1}"
   package_path="${2}"
   file_raise_file_not_found "${package_path}" && ${returnFalse} 
   stage_dir="/tmp/$$$(num_random 999999)"
   if ! _pkgMountAsDirectory \
         ${force_option:-0} \
         "${ssh_node}" \
         "${package_path}" \
         "${stage_dir}"; then
         ${returnFalse} 
   fi
   if _sshRunCommandOnTarget  ${load_arcshell:-0} "${ssh_node}" "(cd ${stage_dir}; ./arcshell_update.sh)"; then
      _sshRunCommandOnTarget ${load_arcshell:-0} "${ssh_node}" "rm -rf ${stage_dir}"
      ${returnTrue}
   else
      _sshRunCommandOnTarget ${load_arcshell:-0} "${ssh_node}" "rm -rf ${stage_dir}"
      ${returnFalse} 
   fi
}

function arc_sync {
   # Uses 'rsync' to sync the current ArcShell home to a remote ArcShell home.
   # >>> arc_sync [-ssh "ssh_connection"] [-setup,-s] [-delete,-d] 
   # -ssh: SSH user@hostname, alias, tag, or group.
   # -setup: Run 'arcshell_setup.sh' after syncing.
   # -delete: Delete remote files if not found locally.
   ${arcRequireBoundVariables}
   typeset setup_option ssh_connection delete_option target_home errors ssh_node
   setup_option=0
   delete_option=0
   ssh_connection="${_g_sshConnection:-}"
   errors=0
   while (( $# > 0)); do
      case "${1}" in
         "-ssh") shift; ssh_connection="${1}" ;;
         "-setup"|"-s") setup_option=1 ;;
         "-delete"|"-d") delete_option=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_empty_var "SSH connection is not set. Use -ssh option." "${ssh_connection}" && ${returnFalse} 
   utl_raise_invalid_option "arc_sync" "(( $# == 0 ))" "$*" && ${returnFalse}  
   echo ""
   echo "Confirm rsync from '${arcHome}' to '${ssh_connection}'."
   echo ""
   utl_confirm || ${returnFalse} 
   while read ssh_node; do
      if _arcSync ${setup_option} ${delete_option} "${ssh_node}"; then
         ((errors=errors+1))
      fi
   done < <(_sshListMembers "${ssh_connection}")
   if (( ${errors} )); then
      ${returnFalse} 
   else
      ${returnTrue} 
   fi
}

function _arcSync {
   # Uses 'rsync' to sync the current ArcShell home to a remote ArcShell home.
   # >>> _arcSync setup_option delete_option "ssh_node"
   # setup_option: 0 or 1. un 'arcshell_setup.sh' after syncing when 1.
   # delete_option: 0 or 1. Delete remote files if not found locally when 1.
   # ssh_node: SSH user@hostname.
   ${arcRequireBoundVariables}
   debug3 "_arcSync: $*"
   utl_raise_invalid_option "_arcSync" "(( $# == 3 ))" "$*" && ${returnFalse} 
   typeset setup_option delete_option ssh_node target_home load_arcshell
   setup_option=${1}
   delete_option=${2}
   ssh_node="${3}"
   target_home="$(_arcReturnArcShellHome "${ssh_node}")"
   load_arcshell=0
   utl_raise_empty_var "Failed to get the location of the remote ArcShell home directory." "${target_home}" && ${returnFalse}    
   if (( ${delete_option} )); then
      delete_option="-delete"
   else
      delete_option=
   fi
   if rsync_dir ${delete_option} -ssh "${ssh_node}" -exclude ".git,user,.gitattributes,.gitignore,nohup.out" "${arcHome}" "${target_home}"; then
      if (( ${setup_option} )); then 
         ! _sshRunCommandOnTarget \
            ${load_arcshell} \
            "${ssh_node}" \
            "${target_home}/arcshell_setup.sh" && \
            ${returnFalse} 
      fi
      ${returnTrue}
   else
      ${returnFalse} 
   fi
}

function arc_uninstall {
   # Remove ArcShell from a remote node.
   # >>> arc_uninstall [-ssh "X"]
   ${arcRequireBoundVariables}
   typeset ssh_connection ssh_node
   ssh_connection="${_g_sshConnection}"
   while (( $# > 0)); do
      case "${1}" in
         "-ssh") shift; ssh_connection="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_empty_var "SSH connection is not set. Use -ssh option." "${ssh_connection}" && ${returnFalse} 
   utl_raise_invalid_option "arc_uninstall" "(( $# == 0 ))" "$*" && ${returnFalse} 
   echo ""
   echo "You are about to remove ArcShell from '${ssh_connection}'."
   echo ""
   utl_confirm || ${returnFalse} 
   while read ssh_node; do
      if ! _arcUninstall "${ssh_node}"; then
         ((errors=errors+1))
      fi
   done < <(_sshListMembers "${ssh_connection}")
   if (( ${errors} )); then
      ${returnFalse} 
   else
      ${returnTrue} 
   fi
}

function _arcUninstall {
   # Remove ArcShell from a single target.
   # >>> _arcUninstall "ssh_node" 
   ${arcRequireBoundVariables}
   debug3 "_arcUninstall: $*"
   typeset ssh_node 
   ssh_node="${1}"
   if arc_run_cmd -ssh "${ssh_node}" "\${arcHome}/arcshell_remove.sh"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function arc_is_daemon_suspended {
   # Returns true if the daemon process is suspended.
   # >>> arc_is_daemon_suspended
   ${arcRequireBoundVariables}
   if [[ "$(flag_get "daemon_suspended")" == "no" ]]; then
      ${returnFalse} 
   else 
      ${returnTrue} 
   fi
}

function _arcshellGetDaemonProcessId {
   # Returns the process ID of the daemon.
   # >>> _arcshellGetDaemonProcessId
   ${arcRequireBoundVariables}
   if [[ -f "${arcTmpDir}/daemon.pid" ]]; then
      cat "${arcTmpDir}/daemon.pid"
   else 
      echo "does_not_exist"
   fi
}

function arc_is_daemon_running {
   # Return true if the ArcShell daemon process appears to be alive.
   # >>> arc_is_daemon_running
   ${arcRequireBoundVariables}
   typeset p 
   p=$(_arcshellGetDaemonProcessId)
   if (( $(ps -ef | grep " ${p} " | egrep "arcshell.sh|bash|ksh" | grep -v "grep" | wc -l) >= 1 )); then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function arc_show {
   # Returns information about the current environment.
   # >>> arc_show
   cat <<EOF
arcNode='${arcNode}'
arcHome='${arcHome}'
arcGlobalHome='${arcGlobalHome}'
arcUserHome='${arcUserHome}'
arc_version='${arc_version}'
EOF
   ssh_show
}

# function arc_generate_compiler_resources {
#    # Generates the maps and requirements for ArcShell core. A lengthy process!
#    # >>> arc_generate_compiler_resources
#    ${arcRequireBoundVariables}
#    typeset tmpFile
#    compiler_create_group "arcshell"
#    compiler_set_group "arcshell"
#    tmpFile="$(mktempf "ArcShellCore")"
#    _arcListCoreFiles > "${tmpFile}"
#    compiler_define_group "${tmpFile}"
#    compiler_generate_resources "arcshell" "${tmpFile}"
#    rmtempf "ArcShellCore"
# }

function arc_run_cmd {
   # Run a command on a remote node within the remote ArcShell environment.
   # >>> arc_run_cmd [-ssh "X"] [-local,-l] "command"
   # -ssh: SSH user@hostname, alias, tag, or group.
   # command: The command to run.
   ${arcRequireBoundVariables}
   typeset allow_local ssh_connection command load_arcshell
   allow_local=0
   load_arcshell=1
   ssh_connection="${_g_sshConnection:-}"
   while (( $# > 0)); do
      case "${1}" in
         "-ssh") shift; ssh_connection="${1}" ;;
         "-local"|"-l") allow_local=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "arc_run_cmd" "(( $# == 1 ))" "$*" && ${returnFalse} 
   command="${1}"
   if _sshRunCommandOnTargets ${load_arcshell} ${allow_local} "${ssh_connection}" "${command}"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _arcReturnArcShellHome {
   # Return ArcShell home using the ~/.arcshell file on the remote node.
   # >>> _arcReturnArcShellHome "ssh_node"
   # ssh_node: SSH user@hostname.
   ${arcRequireBoundVariables}
   debug3 "_arcReturnArcShellHome: $*"
   typeset ssh_node source_arcshell
   ssh_node="${1}"
   _sshRaiseIsNotANodeOrNodeAlias "${ssh_node}" && ${returnFalse} 
   if _sshRunCommandOnTarget ${source_arcshell:-1} "${ssh_node}" "eval echo \\\${arcHome}"; then
      ${returnTrue} 
   else
      log_error -2 -logkey "arcshell" "ArcShell home not found: $*: _arcReturnArcShellHome"
      ${returnFalse} 
   fi
}

function arc_pkg {
   # Package ArcShell and save it to the user or global packages configuration folder.
   # >>> arc_pkg [-global,-g|-local,-l] ["package_name"]
   # -global: Create a global package instead of local.
   # -local: Create a local package (default).
   # package_name: Package name. Defaults to "ArcShell_" with a datetime string.
   ${arcRequireBoundVariables}
   debug3 "arc_pkg: $*"
   typeset package_name target_dir stage_dir
   package_name="ArcShell_$(dt_ymd_hms)"
   target_dir="${_g_arcLocalPackagesDir}"
   while (( $# > 0)); do
      case "${1}" in
         "-global"|"-g") target_dir="${_g_arcGlobalPackagesDir}" ;;
         "-local" |"-l") target_dir="${_g_arcLocalPackagesDir}"  ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "arc_pkg" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   (( $# > 0 )) && package_name="ArcShell_${1}"
   stage_dir="${arcHome}/../${package_name}" 
   # Extremely long file names where causing issues in Windows mounted VirtualBox drives.
   #stage_dir="/tmp/${package_name}"
   cp -rp "${arcHome}" "${stage_dir}" 
   if pkg_dir -exclude ".git,.gitignore,.gitattributes,user" -saveto "${target_dir}" "${stage_dir}"; then
      # rm alone was throwing 'rm: cannot remove...Directory not empty' error. Probably
      # something to do with vbox/Windows disk issue. Adding this 'find' to fix.
      find "${stage_dir}" -type f -exec rm -f {} \;
      rm -rf "${stage_dir}"
      log_boring -logkey "arcshell" -tags "package" "Created new ArcShell package '${_g_pkgWorkingFile}'."
      ${returnTrue}
   else
      find "${stage_dir}" -type f -exec rm -f {} \;
      rm -rf "${stage_dir}"
      ${returnFalse}
   fi
}

function arc_secure_home {
   # Secure file and directory permissions in ArcShell directories.
   # >>> arc_secure_home
   ${arcRequireBoundVariables}
   typeset f
   timer_create -s -f 
   log_terminal "Securing ArcShell..."
   find "${arcHome}" -type f -name "*.sh" -exec chmod 700 {} \;
   find "${arcTmpDir}" -type f -name "*.sh" -exec chmod 700 {} \;
   find "${arcHome}" -type d -exec chmod 700 {} \;
   find "${arcTmpDir}" -type d -exec chmod 700 {} \;
   while read f; do
      chmod 600 "${f}"
   done < <(find "${arcHome}" -type f | egrep -v "\.sh$")
   while read f; do
      chmod 600 "${f}"
   done < <(find "${arcTmpDir}" -type f | egrep -v "\.sh$")
   find "${arcLogDir}" -type f -exec chmod 600 {} \;
   chmod 700 "${arcHome}"
   chmod 700 "${arcTmpDir}"
   chmod 700 "${arcLogDir}"
   log_terminal "ArcShell files and folders are secured. Task completed in $(timer_seconds)s."
   timer_delete
}

