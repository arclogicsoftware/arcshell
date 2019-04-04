
# module_name="Boot"
# module_about="Things we need to load or do first."
# module_version=1
# module_image="power.png"
# copyright_notice="Copyright 2019 Arclogic Software"

function __readmeArcShellBoot {
  cat <<EOF
> If your bug has a one in a million chance of happening, it'll happen next Tuesday. -- Anonymous

# Boot

**Things we need to load or do first.**
EOF
}

# Remove any aliases that force user interaction.
if alias rm 1>/dev/null 2> /dev/null; then
  unalias rm
fi
if alias cp 1>/dev/null 2> /dev/null; then
  unalias cp
fi

function boot_return_with_shbang {
  # Return the file contents with a shbang added for Bash or Korn shell.
  # >>> boot_return_with_shbang "file"
  ${arcRequireBoundVariables}
  typeset file
  file="${1}"
  file_raise_file_not_found "${file}" && ${returnFalse} 
  if boot_is_valid_bash; then
     echo "#!$(which bash)"
  elif boot_is_valid_ksh; then
     echo "#!$(which ksh)"
  fi
  grep -v "^#!" "${file}"
}

function _bootSetsUpRuntime {
  # Used to configure minimal environment for scripts built with the compiler.
  # >>> _bootSetsUpRuntime
  cat <<'EOF'
mkdir -p "${HOME}/arclogic/arcshell"
arcHome="${HOME}/arcshell"
ARC_HOME="${HOME}/arcshell"
mkdir -p "${arcHome}"
arcUserHome="${arcHome}"
ARC_USER_HOME="${arcUserHome}"
arcGlobalHome="${arcHome}"
ARC_GLOBAL_HOME="${arcGlobalHome}"
arcTmpDir="${arcHome}/tmp"
ARC_TMP_DIR="${arcTmpDir}"
mkdir -p "${arcTmpDir}"
arcLogDir="${arcUserHome}/log"
ARC_LOG_DIR="${arcLogDir}"
mkdir -p "${arcLogDir}"
arcLogFile="${arcLogDir}/arcshell.out"
ARC_LOG_FILE="${arcLogFile}"
arcErrFile="${HOME}/arcshell.err"
ARC_ERR_FILE="${HOME}/arcshell.err"
arcEditor=${EDITOR:-"vi"}
EOF
}

function stdout_banner {
  # Returns a simple unix commented banner to ```stdout```.
  # >>> stdout_banner "str"
  # str: Banner string.
  ${arcRequireBoundVariables}
  cat <<EOF
# -----------------------------------------------------------------------------
# ${1}
# -----------------------------------------------------------------------------
EOF
}

function stderr_banner {
  # Returns a simple unix commented banner to ```stderr```.
  # >>> stderr_banner "str"
  # str: Banner string.
  ${arcRequireBoundVariables}
  (
  cat <<EOF
# -----------------------------------------------------------------------------
# ${1}
# -----------------------------------------------------------------------------
EOF
  ) 3>&1 1>&2 2>&3
}

function _arcshell_banner {
   cat <<EOF                             
     _               ____  _          _ _ 
    / \   _ __ ___  / ___|| |__   ___| | |
   / _ \ | '__/ __| \___ \| '_ \ / _ \ | |
  / ___ \| | | (__   ___) | | | |  __/ | |
 /_/   \_\_|  \___| |____/|_| |_|\___|_|_|                      
                          
ArclogicSoftware.com
Copyright 2019 ArcLogic Software
All Rights Reserved
Apache License 2.0
EOF
}

function _arcshell_log {
   echo "${1}"
}

function boot_is_valid_ksh {
  # Return true if current shell is ksh.
  # >>> boot_is_valid_ksh
   if [[ -n "${KSH_VERSION:-}" ]] && (( $(echo ${SECONDS:-} | grep "\." | wc -l) > 0 )); then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function boot_is_valid_bash {
  # Return true if current shell is bash.
  # >>> boot_is_valid_bash
   if [[ -n "${BASH:-}" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function boot_return_shell_type {
  # Return a string to identify the shell type, either 'bash' or 'ksh'.
  # >>> boot_return_shell_type
  # Check for ksh in even BASH variable has been exported to ksh. I don't think
  # it works the same way going from ksh to bash.
  if boot_is_valid_ksh; then
    echo "ksh"
  elif boot_is_valid_bash; then
    echo "bash"
  else 
    _bootThrowError "Invalid shell type: '$0': boot_return_shell_type"
  fi
}

# arcHostname: Stores name of local host.
arcHostname="$(hostname)"
arcUser="${LOGNAME}"
arcHost="$(hostname)"
arcNode="${arcUser}@${arcHost}"
arcOSType="$(uname -s | tr '[:lower:]' '[:upper:]' | tr -d ' ')"
arcShellType="$(boot_return_shell_type)"
exitTrue="exit 0"
returnTrue="return 0"
exitFalse="exit 1"
returnFalse="return 1"
arcRequireBoundVariables="set -o nounset"
arcAllowUnboundVariables="set +o nounset"

function _arcshell_timestamp {
   date +"%Y-%m-%d_%H%M%S"
}

function boot_is_dir_within_dir {
   # Return true if first directory is a subdirectory of second directory.
   # >>> boot_is_dir_within_dir "first directory" "second directory"
   typeset dir1 dir2 d  
   dir1="${1}"
   dir2="${2}"
   while read d; do
      if [[ "${d}" -ef "${dir1}" ]]; then
         ${returnTrue}
      fi
   done < <(find "${dir2}" -type d)
   ${returnFalse}
}

function test_boot_is_dir_within_dir {
   :
}

function _bootThrowError {
   throw_error "arcshell_boot.sh" "${1}"
}

function throw_error {
   # Returns text string as a "sanelog" ERROR string to standard error. 
   # >>> throw_error "sourceText" "errorText"
   # sourceText: Text to identify the source of the error, often library file name.
   # errorText: Text of error message.
   ${arcRequireBoundVariables}
   typeset errorSource errorText
   errorSource="${1:-$$}"
   errorText="${2:-}"
   sanelog "ERROR" "${errorSource}" "${errorText}" 3>&1 1>&2 2>&3
}

function test_throw_error {
   throw_error "bootstrap.sh" "BIZBAZ" 2>&1 | assert_match "ERROR"
}

function throw_message {
   # Returns text string as a "sanelog" MESSAGE string to standard error. 
   # >>> throw_message "messageSource" "messageText"
   # messageSource: Text to identify the source of the message, often library file name.
   # messageText: Text of message.
   ${arcRequireBoundVariables}
   typeset messageSource messageText
   messageSource="${1:-$$}"
   messageText="${2:-}"
   sanelog "MESSAGE" "${messageSource}" "${messageText}" 3>&1 1>&2 2>&3
}

function test_throw_message {
   throw_error "bootstrap.sh" "BIZBAZ" 2>&1 | assert_match "ERROR"
}

function sanelog {
   # Applies log file formating to inputs and returns to standard out.
   # > This function influenced by logsna project. https://github.com/rspivak/logsna
   # >>> sanelog "keywordText" "sourceText" "logText"
   ${arcRequireBoundVariables}
   printf "%s [%s] %s\n" "${1}" "$(date +'%Y-%m-%d %H:%M:%S')" "${2}: ${3:-}"
}

function test_sanelog {
   sanelog "TEST" "foo.bar" "blah" | grep "^TEST.*\[.*\].*foo.bar.*blah" | wc -l | assert 1
}

function boot_get_file_blurb {
  # Return the blurb at the top of most modules.
  # >>> boot_get_file_blurb
  ${arcRequireBoundVariables}
  typeset x file_name 
  file_name="${1}"
  x="$(grep "^# module_about=" "${file_name}" | head -1 | ${arcAwkProg} -F"=" '{print $2}' | sed 's/"//g')"
  [[ -n "${x}" ]] && echo "${x}"
}

function boot_return_tty_device {
   # Returns the tty ID number. Returns zero if "not a tty".
   # >>> boot_return_tty_device
   if tty | grep "not" 1>/dev/null; then
      echo 0
   else 
      basename "$(tty)"
   fi
}

function is_tty_device {
   # Return true if device is a tty device.
   # is_tty_device 
   if tty | grep "not" 1>/dev/null; then
      ${returnFalse} 
   else 
      ${returnTrue} 
   fi
}

_tty=$(boot_return_tty_device)

if ! boot_is_valid_bash && ! boot_is_valid_ksh; then
   _bootThrowError "ArcShell should only be run within a bash or ksh shell."
fi

is_tty_device && _g_debug_terminal=1

function boot_list_functions {
  # List all of the functions in a file.
  # >>> boot_list_functions "file"
  ${arcRequireBoundVariables}
  typeset file 
  file="${1}"
  egrep "^function .*{" "${file}" | awk '{print $2}'
  egrep "^[A-Z|a-z].*\(\).*{" "${file}" | grep -v "^# " | awk '{print $1}'
}

function boot_list_arcshell_homes {
  # Return a list of the Archell homes (application, global, and user).
  # >>> boot_list_arcshell_homes
  [[ -d "${arcHome:-}" ]] && echo "${arcHome}"
  [[ -d "${arcGlobalHome:-}" ]] && echo "${arcGlobalHome}"
  [[ -d "${arcUserHome:-}" ]] && echo "${arcUserHome}"
  ${returnTrue} 
}

function boot_is_file_gz_zipped {
   # Return true if the file ends in .gz.
   # >>> boot_is_file_gz_zipped "file"
   ${arcRequireBoundVariables}
   typeset file 
   file="${1}"
   if (( $(echo "${file}" | grep "\.gz$" | wc -l) )); then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_boot_is_file_gz_zipped {
   boot_is_file_gz_zipped "foo.tar.gz" && pass_test || fail_test
   ! boot_is_file_gz_zipped "foo.tar" && pass_test || fail_test
}

function boot_is_file_compressed {
   # Return true if the file ends in .Z.
   # >>> boot_is_file_compressed "file"
   ${arcRequireBoundVariables}
   typeset file 
   file="${1}"
   if (( $(echo "${file}" | grep "\.Z$" | wc -l) )); then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_boot_is_file_compressed {
   boot_is_file_compressed "foo.tar.Z" && pass_test || fail_test
   ! boot_is_file_compressed "foo.tar" && pass_test || fail_test
}

function boot_is_file_archive {
   # Return true if the file ends in .tar.
   # >>> boot_is_file_archive "file"
   ${arcRequireBoundVariables}
   typeset file 
   file="${1}"
   if (( $(echo "${file}" | grep "\.tar$" | wc -l) )); then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_boot_is_file_archive {
   boot_is_file_archive "foo.tar" && pass_test || fail_test
   ! boot_is_file_archive "foo.txt" && pass_test || fail_test
}

function boot_is_program_found {
   # Return true if program appears to be available.
   # >>> boot_is_program_found "program name or path"
   ${arcRequireBoundVariables}
   typeset file
   file="${1}"
   if [[ -f "${file}" || -f $(which "${file}" 2> /dev/null) ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_boot_is_program_found {
   boot_is_program_found "/bin/bas" && pass_test || fail_test "/bin/bash is a program."
   boot_is_program_found "ls" && pass_test || fail_test "ls is a program."
   boot_is_program_found "/tmp/does_not_exist" && fail_test "Non-existent file is not a program." || pass_test
}

function boot_raise_program_not_found {
  # Throw error and return true if the program is not found.
  # >>> boot_raise_program_not_found "program"
  ${arcRequireBoundVariables}
  typeset program 
  program="${1:-}"
  if ! boot_is_program_found "${program:-}"; then
    _bootThrowError "Program not found, check to see if it is installed or not in your \$PATH: $*: boot_raise_program_not_found"
    ${returnTrue} 
  else 
    ${returnFalse} 
  fi
}

function boot_is_sunos {
  if [[ "${arcOSType}" == "SUNOS" ]]; then
    ${returnTrue} 
  else
    ${returnFalse} 
  fi
}

function boot_does_function_exist {
  # Return true if the function is loaded in the environment.
  # >>> boot_does_function_exist "function name"
  ${arcRequireBoundVariables}
  if [[ "${arcShellType}" == "bash" ]]; then
    type -t "${1}" 1> /dev/null && ${returnTrue} 
  elif [[ "${arcShellType}" == "ksh" ]]; then
    typeset -f "${1}" 1> /dev/null && ${returnTrue} 
  fi
  ${returnFalse} 
}

function boot_hello_sunos {
  # 
  # >>> boot_hello_sunos 
  ${arcRequireBoundVariables}
  echo ""
  stdout_banner "Looks like you are running Solaris..."
  # Most awk commands fail on SUNOS, so we need to check for nawk.
  if boot_is_program_found "nawk"; then
    _arcshell_log "OK -> 'nawk' found."
  else
    throw_error "A whole bunch of 'awk' commands are about to fail. You will need to install 'nawk'."
  fi
  if boot_is_program_found "perl"; then
    _arcshell_log "OK -> 'perl' found."
  else
    throw_error "'str_uniq' function may not work because 'perl' is not installed but we may be able to use 'nawk'."
  fi
}

if boot_is_program_found "nawk"; then
  arcAwkProg="nawk"
else
  arcAwkProg="awk"
fi 

function boot_is_aux_instance {
  # Return true if the current ArcShell instance is an auxilliary instance.
  # >>> boot_is_aux_instance
  if is_truthy "${arcAuxInstance:-0}"; then
    ${returnTrue} 
  else
    ${returnFalse} 
  fi
}

# Solaris 11 bug in /etc/ksh.kshrc when LC_ALL is unset and -u is set. For now
# we will check .profile and if PS1 is not set we will set it.
if boot_is_valid_ksh && [[ "${arcOSType}" == "SUNOS" ]]; then
  if (( $(echo "${PS1}" | grep LC_ALL | wc -l | tr -d ' ') )); then
    export PS1="${LOGNAME}@$(hostname):\${PWD} \$ "
  fi
fi

if ! boot_is_program_found "bc"; then
  stderr_banner "'bc' is not installed! 'bc' is required for the proper operation of ArcShell."
  ${returnFalse} 
fi

if ! boot_is_program_found "rsync"; then
  stderr_banner "'rsync' is not installed! 'rsync' might be required in the future to update ArcShell."
fi

${arcRequireBoundVariables}

arcshellBootstrapLoaded=1

