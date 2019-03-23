

# module_name="Application Logger"
# module_about="Logs and keeps track of events."
# module_version=1
# module_image="infinity.png"
# copyright_notice="Copyright 2019 Arclogic Software"

# Note: In general don't debug the logging module. Try to keep this module free of debug calls.

[[ -z "${arcTmpDir}" ]] && ${returnFalse} 

_loggerHome="${arcTmpDir}/_arcshell_logger"
mkdir -p "${_loggerHome}"
_g_log_default_log_file="${arcLogFile:-"${arcLogDir}/arcshell.log"}"
touch "${_g_log_default_log_file}"

_g_log_to_log=1
_g_log_to_stdout=0
_g_log_to_stderr=0
_g_log_log_file=
_g_log_to_log_once=0
_g_log_to_stdout_once=0
_g_log_to_stderr_once=0
_g_log_messaging_enabled=0
_g_log_follow_pid=

function _logMessagingInterface {
   #
   #
   :
}

function _logReturnLogFile {
   # Return the active log file.
   # >>> _logReturnLogFile
   ${arcRequireBoundVariables}
   typeset x 
   if [[ -n "${_g_log_log_file:-}" ]]; then
      echo "${_g_log_log_file}"
   else
      echo "${_g_log_default_log_file}"
   fi
}

function log_set_default {
   # Set all settings back to default values.
   # >>> log_set_default 
   log_set_file "${_g_log_default_log_file}"
   _g_log_to_log=1
   _g_log_to_stdout=0
   _g_log_to_stderr=0
   _g_log_log_file=
}

function log_show {
   # Returns current coniguration settings.
   # >>> log_show
   ${arcRequireBoundVariables}
   cat <<EOF
The current log file is set to "$(_logReturnLogFile)"...
> $(ls -alrt "$(_logReturnLogFile)" 2> /dev/null)
To change the file, run the following:
log_set_file "\${path_to_log_file}"
Log entries are currently being written to:
EOF
(( ${_g_log_to_log} )) && echo "> '$(_logReturnLogFile)'"
(( ${_g_log_to_stdout} )) && echo "> STDOUT"
(( ${_g_log_to_stderr} )) && echo "> STDERR"
cat <<EOF
To change the output targets run the 'log_set_output' command.
Run 'log_help' or 'log_help -aa' for more.
EOF
}

function log_set_output {
   # Sets the log output targets for the current session.
   # >>> log_set_output [-0] [-1|-2]
   # -0: Log to log file.
   # -1: Log to standard out.
   # -2: Log to standard error.
   ${arcRequireBoundVariables}
   typeset output_targets 
   _g_log_to_log=0
   _g_log_to_stdout=0
   _g_log_to_stderr=0
    while (( $# > 0)); do
      case "${1}" in
         "-0") _g_log_to_log=1 ;;
         "-1") _g_log_to_stdout=1; _g_log_to_stderr=0 ;;
         "-2") _g_log_to_stdout=0; _g_log_to_stderr=1 ;;
         *) break ;;
      esac
      shift
   done
}

function log_set_file {
   # Set the file being logged to a non-default file.
   # >>> log_set_file "file"
   # file: Path to file you want to begin logging to.
   ${arcRequireBoundVariables}
   _g_log_log_file="${1}"
   if [[ ! -f "${_g_log_log_file}" ]]; then
      if touch "${_g_log_log_file}"; then
         rm "${_g_log_log_file}"
      else
         _g_log_log_file=
      fi
   fi
}

function log_follow {
   # Tail the arcshell application log as a background process. 'fg' to bring to foreground.
   # >>> log_follow
   ${arcRequireBoundVariables}
   typeset f 
   f="$(_logReturnLogFile)"
   tail -f "${f}" &
   _g_log_follow_pid=$!
}

function log_quit {
   # Kills the "log_follow" process if it is running.
   # >>> log_quit
   ${arcRequireBoundVariables}
   if num_is_num ${_g_log_follow_pid:-}; then
      if os_is_process_id_process_name_running ${_g_log_follow_pid} "tail"; then
         kill -9 ${_g_log_follow_pid}
      else 
         jobs
         _logThrowError "'log_follow' process not found: ${_g_log_follow_pid}: log_quit"
      fi 
   else 
      jobs
      _logThrowError "'log_follow' process not defined: $*: log_quit"
   fi
   _g_log_follow_pid=
}

function log_open {
   # Open ArcShell application log file in the default editor.
   # >>> log_open 
   ${arcRequireBoundVariables}
   typeset f 
   f="$(_logReturnLogFile)"
   "${arcEditor:-vi}" "${f}"
}

function _log_to_app_log {
   # Logs standard input to the appropriate targets.
   # >>> _log_to_app_log
   ${arcRequireBoundVariables}
   typeset x f 
   x="$(cat)"
   f="$(_logReturnLogFile)"
   if (( ${_g_log_to_stdout_once} || ${_g_log_to_stdout} )); then
      echo "${x}"
   fi
   if (( ${_g_log_to_stderr_once} || ${_g_log_to_stderr} )); then
      echo "${x}" 3>&1 1>&2 2>&3
   fi
   if (( ${_g_log_to_log} )); then
      echo "${x}" >> "${f}"
   fi
   _g_log_to_stdout_once=0
   _g_log_to_stderr_once=0
}

function _log_log_type {
   # Log a an entry of type to the current log file.
   # >>> _log_log_type "log_entry_type" "log_key" "log_text" ["tags"]
   ${arcRequireBoundVariables}
   typeset log_type log_key log_text tags tag_list
   log_type="${1}"
   log_key="${2}"
   log_text="${3}"
   tags="${4:-}"
   printf "%s %s %s %s %s %s %s\n" "$(dt_epoch)" "${log_type}" "[${log_key:-}]" "${LOGNAME}@$(hostname)" "$(date +'%Y-%m-%d %H:%M:%S')" "[${tags:-}]" "${log_text}" | _log_to_app_log
   tag_list="$(echo "${tags}" | tr "," "|")"
   counters_set "logging,log_type,${log_type},+1"
}

function log_terminal {
   # Return text to standard out if the call is originating from a terminal.
   # > Note: Terminal is zero in a Bash sub-shell even if the code is invoked from a terminal.
   # >>> log_terminal "log_text"
   # log_text: The text to log.
   # __logging_disable_terminal_log_entries: Set to truthy value to disable writing these values to the log file.
   ${arcRequireBoundVariables}
   if is_tty_device; then
      echo "${1:-}" 3>&1 1>&2 2>&3
   else
      if is_truthy "${__logging_disable_terminal_log_entries:-'n'}"; then
         _log_log_type "TERMINAL" "$$" "${1:-}" "tty$(boot_return_tty_device)"
      fi
   fi
}

function log_boring {
   # Log "boring" text to the application log file.
   # >>> log_boring [-stdin] [-1|-2] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
   # -stdin: Read standard input.
   # -1: Data is returned to standard out in addition to being logged.
   # -2: Data is returned to standard error in addition to being logged.
   # -logkey: A key to identify the primary source of the log entry.
   # -tags: Tag list.
   # log_text: Text to log.
   ${arcRequireBoundVariables}
   typeset log_key log_text tags stdin
   log_key=$$
   tags=
   stdin=0
   while (( $# > 0)); do
      case "${1}" in
         "-1") _g_log_to_stdout_once=1                         ;;
         "-2") _g_log_to_stderr_once=1                         ;;
         "-stdin") stdin=1                                     ;;
         "-tags"|"-tag"|"-t") shift; tags="$(utl_format_tags "${1}")" ;;
         "-logkey"|"-l")  shift; log_key="${1}"                   ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "log_boring" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   log_text="${1:-}"
   _log_log_type "BORING" "${log_key}" "${log_text}" "${tags:-}"
   if (( ${stdin} )); then
      cat | log_detail 
   fi
}

function log_info {
   # Log informational text to the application log file.
   # >>> log_info [-stdin] [-1|-2] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
   # -stdin: Read standard input.
   # -1: Data is returned to standard out in addition to being logged.
   # -2: Data is returned to standard error in addition to being logged.
   # -logkey: A key to identify the primary source of the log entry.
   # -tags: Tag list.
   # log_text: Text to log.
   ${arcRequireBoundVariables}
   typeset log_key log_text tags stdin
   log_key=$$
   tags=
   stdin=0
   while (( $# > 0)); do
      case "${1}" in
         "-1") _g_log_to_stdout_once=1                         ;;
         "-2") _g_log_to_stderr_once=1                         ;;
         "-stdin") stdin=1                                     ;;
         "-tags"|"-tag"|"-t") shift; tags="$(utl_format_tags "${1}")" ;;
         "-logkey"|"-l")  shift; log_key="${1}"                   ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "log_info" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   log_text="${1:-}"
   _log_log_type "INFO" "${log_key}" "${log_text}" "${tags:-}"
   if (( ${stdin} )); then
      cat | log_detail 
   fi
}

function log_notice {
   # Log a 'NOTICE' to the current log file.
   # >>> log_notice [-stdin] [-1|-2] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
   # -stdin: Read standard input.
   # -1: Data is returned to standard out in addition to being logged.
   # -2: Data is returned to standard error in addition to being logged.
   # -logkey: A key to identify the primary source of the log entry.
   # -tags: Tag list.
   # log_text: Text to log.
   ${arcRequireBoundVariables}
   typeset log_key log_text tags stdin
   log_key=$$
   tags=
   stdin=0
   while (( $# > 0)); do
      case "${1}" in
         "-1") _g_log_to_stdout_once=1                         ;;
         "-2") _g_log_to_stderr_once=1                         ;;
         "-stdin") stdin=1                                     ;;
         "-tags"|"-tag"|"-t") shift; tags="$(utl_format_tags "${1}")" ;;
         "-logkey"|"-l")  shift; log_key="${1}"                   ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "log_notice" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   log_text="${1:-}"
   _log_log_type "NOTICE" "${log_key}" "${log_text}" "${tags:-}"
   if (( ${stdin} )); then
      cat | log_detail 
   fi
}

function log_event {
   # Log a 'EVENT' record to the current log file.
   # >>> log_event [-stdin] [-1|-2] [-tags,-t "X,x"] "log_text"
   # -stdin: Read standard input.
   # -1: Data is returned to standard out in addition to being logged.
   # -2: Data is returned to standard error in addition to being logged.
   # -logkey: A key to identify the primary source of the log entry.
   # -tags: Tag list.
   # log_text: Text to log.
   ${arcRequireBoundVariables}
   typeset tags event_name event_text stdin
   tags="x"
   event_name= 
   event_text=
   stdin=0
   while (( $# > 0)); do
      case "${1}" in
         "-1") _g_log_to_stdout_once=1                         ;;
         "-2") _g_log_to_stderr_once=1                         ;;
         "-stdin") stdin=1                                     ;;
         "-tags"|"-tag"|"-t") shift; tags="$(utl_format_tags "${1}")" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "log_event" "(( $# == 2 ))" "$*" && ${returnFalse} 
   event_name="${1}"
   event_text="${2}"
   _log_log_type "EVENT" "${event_name}" "${event_text}" "${tags:-}"
   if (( ${stdin} )); then
      cat | log_detail 
   fi
}

function log_data {
   # Log a 'DATA' record to the current log file.
   # >>> log_data [-stdin] [-1|-2] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
   # -stdin: Read standard input.
   # -1: Data is returned to standard out in addition to being logged.
   # -2: Data is returned to standard error in addition to being logged.
   # -logkey: A key to identify the primary source of the log entry.
   # -tags: Tag list.
   # log_text: Text to log.
   ${arcRequireBoundVariables}
   typeset log_key log_text tags stdin
   log_key=$$
   tags=
   stdin=0
   while (( $# > 0)); do
      case "${1}" in
         "-1") _g_log_to_stdout_once=1                         ;;
         "-2") _g_log_to_stderr_once=1                         ;;
         "-stdin") stdin=1                                     ;;
         "-tags"|"-tag"|"-t") shift; tags="$(utl_format_tags "${1}")" ;;
         "-logkey"|"-l")  shift; log_key="${1}"                   ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "log_data" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   log_text="${1:-}"
   _log_log_type "DATA" "${log_key}" "${log_text}" "${tags:-}"
   if (( ${stdin} )); then
      cat | log_detail 
   fi
}

function log_message {
   # Log a 'MESSAGE' record to the current log file.
   # >>> log_message [-stdin] [-1|-2] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
   # -stdin: Read standard input.
   # -1: Data is returned to standard out in addition to being logged.
   # -2: Data is returned to standard error in addition to being logged.
   # -logkey: A key to identify the primary source of the log entry.
   # -tags: Tag list.
   # log_text: Text to log.
   ${arcRequireBoundVariables}
   typeset log_key log_text tags stdin
   log_key=$$
   tags=
   stdin=0
   while (( $# > 0)); do
      case "${1}" in
         "-1") _g_log_to_stdout_once=1                         ;;
         "-2") _g_log_to_stderr_once=1                         ;;
         "-stdin") stdin=1                                     ;;
         "-tags"|"-tag"|"-t") shift; tags="$(utl_format_tags "${1}")" ;;
         "-logkey"|"-l")  shift; log_key="${1}"                   ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "log_message" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   log_text="${1:-}"
   _log_log_type "MESSAGE" "${log_key}" "${log_text}" "${tags:-}"
   if (( ${stdin} )); then
      cat | log_detail 
   fi
}

function log_critical {
   # Log a 'CRITICAL' record to the current log file.
   # >>> log_critical [-stdin] [-1|-2] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
   # -stdin: Read standard input.
   # -1: Data is returned to standard out in addition to being logged.
   # -2: Data is returned to standard error in addition to being logged.
   # -logkey: A key to identify the primary source of the log entry.
   # -tags: Tag list.
   # log_text: Text to log.
   ${arcRequireBoundVariables}
   typeset log_key log_text tags stdin
   log_key=$$
   tags=
   stdin=0
   while (( $# > 0)); do
      case "${1}" in
         "-1") _g_log_to_stdout_once=1                         ;;
         "-2") _g_log_to_stderr_once=1                         ;;
         "-stdin") stdin=1                                     ;;
         "-tags"|"-tag"|"-t") shift; tags="$(utl_format_tags "${1}")" ;;
         "-logkey"|"-l")  shift; log_key="${1}"                   ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "log_critical" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   log_text="${1:-}"
   _log_log_type "CRITICAL" "${log_key}" "${log_text}" "${tags:-}"
   if (( ${stdin} )); then
      cat | log_detail 
   fi
}

function log_warning {
   # Log a 'WARNING' record to the current log file.
   # >>> log_warning [-stdin] [-1|-2] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
   # -stdin: Read standard input.
   # -1: Data is returned to standard out in addition to being logged.
   # -2: Data is returned to standard error in addition to being logged.
   # -logkey: A key to identify the primary source of the log entry.
   # -tags: Tag list.
   # log_text: Text to log.
   ${arcRequireBoundVariables}
   typeset log_key log_text tags stdin
   log_key=$$
   tags=
   stdin=0
   while (( $# > 0)); do
      case "${1}" in
         "-1") _g_log_to_stdout_once=1                         ;;
         "-2") _g_log_to_stderr_once=1                         ;;
         "-stdin") stdin=1                                     ;;
         "-tags"|"-tag"|"-t") shift; tags="$(utl_format_tags "${1}")" ;;
         "-logkey"|"-l")  shift; log_key="${1}"                   ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "log_warning" "(( $# == 1 ))" "$*" && ${returnFalse} 
   log_text="${1}"
   if (( ${stdin} )); then
      log_input="$(cat)"
      [[ -z "${log_input:-}" ]] && ${returnFalse} 
   fi
   _log_log_type "WARNING" "${log_key}" "${log_text}" "${tags:-}"
   if [[ -n "${log_input:-}" ]]; then
      echo "${log_input}" | log_detail 
   fi
}

function log_error {
   # Log a 'ERROR' record to the current log file.
   # >>> log_error [-stdin] [-1|-2] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
   # -stdin: Read standard input.
   # -1: Data is returned to standard out in addition to being logged.
   # -2: Data is returned to standard error in addition to being logged.
   # -logkey: A key to identify the primary source of the log entry.
   # -tags: Tag list.
   # log_text: Text to log.
   ${arcRequireBoundVariables}
   typeset log_key log_text tags stdin
   log_key=$$
   tags=
   stdin=0
   while (( $# > 0)); do
      case "${1}" in
         "-1") _g_log_to_stdout_once=1                             ;;
         "-2") _g_log_to_stderr_once=1                             ;;
         "-stdin") stdin=1                                         ;;
         "-tags"|"-tag"|"-t") shift; tags="$(utl_format_tags "${1}")" ;;
         "-logkey"|"-l")  shift; log_key="${1}"                       ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "log_error" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   log_text="${1:-}"
   _log_log_type "ERROR" "${log_key}" "${log_text}" "${tags:-}"
   if (( ${stdin} )); then
      cat | log_detail 
   fi
}

function log_fatal {
   # Log a 'FATAL' record to the current log file.
   # >>> log_fatal [-stdin] [-1|-2] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
   # -stdin: Read standard input.
   # -1: Data is returned to standard out in addition to being logged.
   # -2: Data is returned to standard error in addition to being logged.
   # -logkey: A key to identify the primary source of the log entry.
   # -tags: Tag list.
   # log_text: Text to log.
   ${arcRequireBoundVariables}
   typeset log_key log_text tags stdin
   log_key=$$
   tags=
   stdin=0
   while (( $# > 0)); do
      case "${1}" in
         "-1") _g_log_to_stdout_once=1                         ;;
         "-2") _g_log_to_stderr_once=1                         ;;
         "-stdin") stdin=1                                     ;;
         "-tags"|"-tag"|"-t") shift; tags="$(utl_format_tags "${1}")" ;;
         "-logkey"|"-l")  shift; log_key="${1}"                   ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "log_fatal" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   log_text="${1:-}"
   _log_log_type "FATAL" "${log_key}" "${log_text}" "${tags:-}"
   if (( ${stdin} )); then
      cat | log_detail 
   fi
}

function log_audit {
   # Log a 'AUDIT' record to the current log file.
   # >>> log_audit [-stdin] [-1|-2] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
   # -stdin: Read standard input.
   # -1: Data is returned to standard out in addition to being logged.
   # -2: Data is returned to standard error in addition to being logged.
   # -logkey: A key to identify the primary source of the log entry.
   # -tags: Tag list.
   # log_text: Text to log.
   ${arcRequireBoundVariables}
   typeset log_key log_text tags stdin
   log_key=$$
   tags=
   stdin=0
   while (( $# > 0)); do
      case "${1}" in
         "-1") _g_log_to_stdout_once=1                         ;;
         "-2") _g_log_to_stderr_once=1                         ;;
         "-stdin") stdin=1                                     ;;
         "-tags"|"-tag"|"-t") shift; tags="$(utl_format_tags "${1}")" ;;
         "-logkey"|"-l")  shift; log_key="${1}"                   ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "log_audit" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   log_text="${1:-}"
   _log_log_type "AUDIT" "${log_key}" "${log_text}" "${tags:-}"
   if (( ${stdin} )); then
      cat | log_detail 
   fi
}

function log_detail {
   # Log a set of details to the current log file. Assumes bulk of data is coming from standard input.
   # >>> log_detail [-1|-2]  
   # -1: Data is returned to standard out in addition to being logged.
   # -2: Data is returned to standard error in addition to being logged.
   ${arcRequireBoundVariables}
   typeset log_key log_text
   log_key=$$
   tags=
   while (( $# > 0)); do
      case "${1}" in
         "-1") _g_log_to_stdout_once=1                         ;;
         "-2") _g_log_to_stderr_once=1                         ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "log_detail" "(( $# == 0 ))" "$*" && ${returnFalse} 
   cat | sed 's/^/! /' | _log_to_app_log
}

function log_truncate {
   # Truncates the current log file.
   # >>> log_truncate
   ${arcRequireBoundVariables}
   typeset f 
   f="$(_logReturnLogFile)"
   cp /dev/null "${f}"
}

function log_get {
   # Return one or more lines from the application log file.
   # >>> log_get [X=1]
   # X: Return last X lines from the log file.
   ${arcRequireBoundVariables}
   typeset x 
   x=${1:-1}
   tail -${x} "${_g_log_default_log_file}"
}

function _logThrowError {
   # Error handler for this module.
   # >>> _logThrowError "errorText"
   throw_error "arcshell_logger.sh" "${1}"
}
