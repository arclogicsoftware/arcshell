
# Copyright 2019 Arclogic Software

# Todo: Implement -crontab.

function arcshell_setup_usage {
   cat <<EOF
./arcshell_setup.sh [-usr "X"] [-doc] [-aux] [-reset] [-admin "X"] [-help]

   -usr     : Sets or moves the user home to directory "X". Fails if "X" already exists.
   -doc     : Rebuilds the documentation.
   -main    : Usually only one install per host should be designated main.
   -aux     : Designate the install as an auxilliary install.
   -reset   : Resets the system by deleting all data in the ArcShell temp folder.
   -help    : Get help.

EOF
}

typeset alternate_user_home build_the_docs reset_arcshell

reset_arcshell=0
alternate_user_home=
build_the_docs=0
auxiliary_instance=
install_log_file="${HOME}/arcshell_install.log"
cp /dev/null "${install_log_file}"

function log_setup {
   # Make an log entry during setup.
   # >>> log_setup "text" [stdout]
   # text: Text to log.
   # stdout: 1 or 0, 1 if you want to also return the text to standard out. Defaults to 0.
   echo "${1}" >> "${install_log_file}"
   (( ${2:-0} == 1 )) && echo "${1}"
}

while (( $# > 0)); do
   case "${1}" in
      "-usr") shift; alternate_user_home="${1}" ;;
      "-doc") build_the_docs=1 ;;
      "-aux") auxiliary_instance=1 ;;
      "-main") auxiliary_instance=0  ;;
      "-reset") reset_arcshell=1 ;;
      "-help") arcshell_setup_usage; exit 0 ;;
      *) break ;;
   esac
   shift
done

if [[ ! -f "./arcshell_setup.sh" ]]; then
   cd "$(dirname "$0")" 
fi

arcshellBootstrapLoaded=0

. "$(pwd)/sh/arcshell_boot.sh"

if ! (( ${arcshellBootstrapLoaded:-0} )); then
   echo "Error: Failed to load 'arcshell_boot.sh'."
   exit 1
fi

_arcshell_banner
log_setup "Setting up Arcshell." 1

function _throwArcShellSetupError {
   # Return an error message to standard error.
   # >>> _throwArcShellSetupError "error"
   throw_error "arcshell_setup.sh" "${1}"
}

function _setupRaiseHomeNotDefined {
   #
   #
   if [[ ! -d "${HOME:-}" ]]; then
      _throwArcShellSetupError "'\${HOME}' is not defined or the directory it points to does not exist."
      ${returnTrue} 
   else 
      ${returnFalse} 
   fi
}

function _setupArcShellMoveUserHome {
   #
   # >>> _setupArcShellMoveUserHome "current directory" "new directory"
   ${arcRequireBoundVariables}
   typeset current_dir new_dir 
   current_dir="${1}"
   new_dir="${2}"
   if [[ ! -d "${current_dir}" ]]; then
      log_setup "Can't move '\${arcUserHome}', '${current_dir}' doesn't exist." 1
      ${returnTrue} 
   fi
   if [[ -d "${new_dir}" ]]; then
      _throwArcShellSetupError "Failed to move the user home. '${new_dir}' already exists."
      ${returnFalse} 
   fi
   log_setup "Moving '\${arcUserHome}' from '${current_dir}' to '${new_dir}'." 1
   if cp -rp "${current_dir}" "${new_dir}"; then
      # Don't remove the directory, there are some things pointing to it in the 
      # current session, like debug logs. 
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

if (( $# > 0 )); then
   _throwArcShellSetupError "Error: Argument invalid: Try -help."
   exit 1
fi

if [[ ! -f "./arcshell_setup.sh" ]]; then
   _throwArcShellSetupError "Switch to the directory containing 'arcshell_setup.sh' before running setup."
   ${exitFalse}
fi

log_setup "'$(pwd)' is going to be your '\${arcHome}'."
log_setup "Bootstrap is loaded."
_setupRaiseHomeNotDefined && ${exitFalse}
log_setup "'\${HOME}' is set to ${HOME}."
sleep 3

# Load the current arcshell environment if it is found.

typeset from_version
from_version=209903121129

if [[ -f "${HOME}/.arcshell" ]]; then
   arcHome=
   . "${HOME}/.arcshell"
   from_version=$(arc_version -n)
   log_setup "Looks like ArcShell version $(arc_version) may already be installed."
   if [[ -n "${alternate_user_home:-}" ]] && ! [[ "${alternate_user_home}" != "${arcHome}" ]]; then
      if ! _setupArcShellMoveUserHome "${arcUserHome}" "${alternate_user_home}"; then
         ${exitFalse}
      fi
      arcUserHome="${alternate_user_home}"
   fi  
else
   if [[ -n "${alternate_user_home:-}" ]] && ! [[ "${alternate_user_home}" != "${arcHome}" ]]; then
      arcUserHome="${alternate_user_home}"
   else
      arcUserHome="$(pwd)/user"
   fi
fi

arcVersion="$(cat "$(pwd)/resource/version.txt")"

log_setup "ArcShell version is ${arcVersion}" 1

if [[ -d "${arcTmpDir:-}" ]] && (( ${reset_arcshell} )); then
   rm -rf "${arcTmpDir}"
   mkdir -p "${arcTmpDir}"
fi

export arcHome="$(pwd)"
export arcGlobalHome="${arcHome}/global"
mkdir -p "${arcGlobalHome}" 
mkdir -p "${arcUserHome}"
export arcTmpDir="${arcUserHome}/tmp"
mkdir -p "${arcTmpDir}"
touch "${arcTmpDir}/arcshell.cfg"
export arcLogDir="${arcUserHome}/log"
mkdir -p "${arcLogDir}"
export arcLogFile="${arcLogDir}/arcshell.log"
export arcErrFile="${HOME}/arcshell.err"
# PATH: Add locations for .sh scripts in preferred search order.
export PATH="${PATH}:${arcUserHome}:${arcUserHome}/sh:${arcGlobalHome}:${arcGlobalHome}/sh:${arcHome}:${arcHome}/sh:${arcHome}/sh/core:.:"

function _setupCreateRequiredDirs {
   #
   # >>> _setupCreateRequiredDirs "root directory"
   ${arcRequireBoundVariables}
   typeset root_dir 
   root_dir="${1}"
   if [[ -d "${root_dir}" ]]; then
      for d in "app" "sh" "sql" "tmp" "schedules" "config" "bin"; do
         mkdir -p "${root_dir}/${d}"
         chmod 700 "${root_dir}/${d}"
      done
   else
      _throwArcShellSetupError ""
   fi
}

_setupCreateRequiredDirs "${arcUserHome}"
_setupCreateRequiredDirs "${arcGlobalHome}"

log_setup "Application home \${arcHome} is '${arcHome}'."
log_setup "Global home \${arcGlobalHome} is '${arcGlobalHome}'."
log_setup "User home \${arcUserHome} is '${arcUserHome}'."
log_setup "Date: $(date)"
log_setup "Hostname: $(hostname)"
log_setup "User: ${LOGNAME}"

if ! $(boot_is_valid_bash) && ! $(boot_is_valid_ksh); then
   echo "ArcShell needs to be installed using the Bash or Korn shell."
fi

. "./sh/arcshell_core.sh"

[[ $(os_return_os_type) == "SUNOS" ]] && boot_hello_sunos 

[[ -z "${auxiliary_instance:-}" ]] && auxiliary_instance="${arcAuxInstance:-}"

# Seems to be default for Solaris. Could not save file when editing from arc_menu.
if [[ "${EDITOR:-}" == "gedit" ]]; then
   echo "Changing default EDITOR from 'gedit' to 'vi'."
   EDITOR="vi"
fi

(
cat <<EOF
# Note, this file can be re-generated by running arcshell_setup.sh.
if [[ -z "\${arcHome:-}" ]]; then
   set -a
   # Found at least one environment where LOGNAME was not set.
   [[ -z "${LOGNAME:-}" ]] && LOGNAME="$(whoami)"
   arcVersion="${arcVersion}"
   arcAuxInstance=${auxiliary_instance:-0}
   arcSetupDateTime="$(date)"
   arcHome="${arcHome}"
   ARC_HOME="${arcHome}"
   arcUserHome="${arcUserHome}"
   ARC_USER_HOME="${arcUserHome}"
   arcGlobalHome="${arcGlobalHome}"
   ARC_GLOBAL_HOME="${arcGlobalHome}"
   arcTmpDir="${arcTmpDir}"
   ARC_TMP_DIR="${arcTmpDir}"
   arcLogDir="${arcLogDir}"
   ARC_LOG_DIR="${arcLogDir}"
   arcLogFile="${arcLogFile}"
   ARC_LOG_FILE="${arcLogFile}"
   arcErrFile="${arcErrFile}"
   ARC_ERR_FILE="${arcErrFile}"
   arcVersion=${arcVersion}
   arcEditor="${EDITOR:-"vi"}"
   ARC_EDITOR="${EDITOR:-"vi"}"
   export PATH="\${PATH}:\${arcUserHome}:\${arcUserHome}/sh:\${arcUserHome}/bin:\${arcGlobalHome}:\${arcGlobalHome}/sh:\${arcGlobalHome}/bin:\${arcHome}:\${arcHome}/sh:\${arcHome}/bin"
   [[ -f "\${arcHome}/config/arcshell/arcshell.cfg" ]] && . "\${arcHome}/config/arcshell/arcshell.cfg"
   [[ -f "\${arcGlobalHome}/config/arcshell/arcshell.cfg" ]] && . "\${arcGlobalHome}/config/arcshell/arcshell.cfg"
   [[ -f "\${arcUserHome}/config/arcshell/arcshell.cfg" ]] && . "\${arcUserHome}/config/arcshell/arcshell.cfg"
   . "\${arcHome}/sh/arcshell_core.sh"
   [[ -f "\${arcTmpDir}/_.Help" ]] && . "\${arcTmpDir}/_.Help"
fi
EOF
) > ~/.arcshell

function _setup_returns_special_function_from_file {
   # Returns function name from file if it begins with the 'searchExpression'.
   # >>> _setup_returns_special_function_from_file "searchExpression" "file_name"
   typeset searchExpression file_name  
   searchExpression="${1}"
   file_name="${2}"
   grep "^function ${searchExpression}.*" "${file_name}" | \
      grep -v "_test {" | sed 's/{//' | ${arcAwkProg} '{print $2}'
}

typeset file_name specialFunction x file 

if boot_is_program_found "arcshell.sh"; then
   if arc_is_daemon_running; then
      log_setup "Suspending the ArcShell daemon process..." 1
      arcshell.sh daemon suspend
   fi
fi

log_setup "Running setup functions." 1
while read file_name; do
   specialFunction=$(_setup_returns_special_function_from_file "__setup" "${file_name}")
   if [[ -n "${specialFunction}" ]]; then
      log_setup "${file_name}"
      eval "${specialFunction}"
   fi
done < <(egrep "^function __setup" "${arcHome}/sh/core/"* | ${arcAwkProg} -F":" '{print $1}' | sort -u)

# We can't reload .arcshell unless we set arcHome to nothing.
log_setup "Loading the ArcShell environment." 1
arcHome=
. "${HOME}/.arcshell"

log_setup "Running config functions." 1
while read file_name; do
   specialFunction=$(_setup_returns_special_function_from_file "__config" "${file_name}")
   if [[ -n "${specialFunction}" ]]; then
      eval "${specialFunction}"
   fi
done < <(egrep "^function __config" "${arcHome}/sh/core/"* | ${arcAwkProg} -F":" '{print $1}' | sort -u)

if (( ${build_the_docs} )); then
   doceng_delete_all
fi

! _docengDoesRepoExist "${arcHome}/sh" && doceng_document_dir "${arcHome}/sh"
doceng_document_dir "${arcGlobalHome}/sh"
doceng_document_dir "${arcUserHome}/sh"
_docengCreateSingleLoadableHelpFile

touch "${arcLogFile}"
touch "${arcErrFile}"

log_setup "Generating aliases for ArcShell core..."
# doceng_generate_aliases_file_for_arcshell_core

(
grep "^function " "${arcHome}/sh/core/"*.sh | egrep -v "function test_|function _" | cut -d" " -f2 
grep "^function " "${arcHome}/sh/"*.sh 2>/dev/null | egrep -v "function test_|function _" | cut -d" " -f2 
) | sort > "${arcHome}/sh/_funcs.txt"

boot_return_with_shbang "${arcHome}/resource/arcshell_daemon.sh" > "${arcUserHome}/arcshell.sh"
chmod 700 "${arcUserHome}/arcshell.sh"

log_setup "Securing ArcShell files and directories." 1
#arc_secure_home

log_setup "Running setup.cfg files..." 1
while read f; do
   chmod 700 "${f}"
   log_setup "${f}" 1
   . "${f}"
   # Copy cron_check.sh file to target folder if defined in the setup.cfg.
   if [[ -d "${arcshell_cron_check_dir:-}" ]]; then
      boot_return_with_shbang "${arcHome}/sh/core/cron_check.sh" "${arcshell_cron_check_dir}/cron_check.sh"
      chmod 700 "${arcshell_cron_check_dir}/cron_check.sh"
   fi
done < <(config_return_all_paths_for_object "arcshell" "setup.cfg" )

log_setup "Logging ssh details..." 
if os_get_process_count "sshd" 1>/dev/null ; then
   log_setup "'sshd' process is running"
else
   log_setup "'sshd' process is *NOT* running"
fi
log_setup "SSH key types in use for this account."
log_setup "$(ssh_list_key_types_in_use)"
echo ""
log_setup "*** ArcShell is ready to use. ***" 1

if arc_is_daemon_suspended; then
   log_setup "Starting the ArcShell daemon process..." 1
   nohup arcshell.sh daemon resume &
fi

cat "${install_log_file}" | log_boring -stdin -logkey "arcshell" -tags "Setup Log"

log_boring -logkey "arcshell" -tags "setup" "Setup is complete."

cat <<EOF

*********************************************************************
Like ArcShell? Support it. We provide the following services.
*********************************************************************

   -> Product support, implementation, and management plans.
   -> Consulting
   -> Onsite and remote training.
   -> Custom development and product integration work.
   -> Help building out your automation and monitoring pipelines.

Email to schedule a convenient time to talk.

We can help you maximize the value of this product and more.

Thanks,
Ethan Ray Post
Ethan@ArclogicSoftware.com 

EOF

# Patching Code
if (( ${from_version} <= 201903121129 )); then
   # Remove the delivered file manually if it exists.
   find "${arcHome}/config/schedules" -name "arcshell_collect_server_load" -exec rm {} \;
   # Check to see if user has a copy of this file elsewhere.
   if sch_does_task_exist "arcshell_collect_server_load.sh"; then
      log_error -2 -logkey "arcshell" -tags "deprecated" "arcshell_collect_server_load.sh scheduled task is deprecated."
   fi
fi

if (( ${from_version} <= 201903202348 )); then
   sch_delete_task "arcshell_check_alerts.sh"
   sch_delete_task "arcshell_check_message_queues.sh"
   sch_delete_task "arcshell_check_for_reboot.sh"
   sch_delete_task "arcshell_run_misc_tasks_05m.sh"
   sch_delete_task "arcshell_run_misc_tasks_10m.sh"
   sch_delete_task "arcshell_10m_tasks.sh"
   if [[ -f "${arcHome}/schedules/01m/arcshell_monitor_cpu_usage.sh" ]]; then
      mv "${arcHome}/schedules/01m/arcshell_monitor_cpu_usage.sh" \
         "${arcHome}/schedules/05m/"
   fi
   sch_delete_task "arcshell_hourly_tasks.sh"
fi

