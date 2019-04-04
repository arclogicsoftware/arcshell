
# module_name="Debug"
# module_about="Provides advanced debug capabiltiies."
# module_version=1
# module_image="blueprint.png"
# copyright_notice="Copyright 2019 Arclogic Software"

[[ -z "${arcTmpDir}" ]] && ${returnFalse} 

_debugDir="${arcTmpDir}/_debug"
mkdir -p "${_debugDir}"

# Global configuration variables for the Debug module.
_g_debug_file="${_g_debug_file:-"${arcLogDir}/debug.log"}"
_g_debug_level=${_g_debug_level:-0}
_g_debug_output=${_g_debug_output:-0}

# Variables used for session level debug capabilities.
_g_debug_session_file="${_debugDir}/debug.$$"
_g_debug_session_level=0

function __readmeDebug {
   ${arcAllowUnboundVariables}
   cat <<EOF

> If debugging is the process of removing software bugs, then programming must be the process of putting them in. --Edsger Dijkstra

## Features
* Enable debug globally or at the process level.
* Integrates with the Arclogic unit test library.
* In addition to regular log files direct debug to standard error or standard out.

## Get Started
To use the debug library source it into your script or shell. Sourcing in the debug.sh library, a few ways.
\`\`\`
# Only works if file is in current \${PATH} or "." is in current \${PATH}.
. debug.sh

# Only works if file is in current directory.
# . ./debug.sh

# Full path can present issues porting to other hosts if paths are not the same.
# . /home/arcshell/core/debug.sh
\`\`\`
Let's make some debug calls. 
\`\`\`
# Setting a variable up for the example call below.
$ RESUME_NAME="John Doe" 

# Set the _g_debug_level to 3 so all of our statements are actually captured.
$ export _g_debug_level=3

# My preference for debug1 calls is to try to limit them to plain english.
$ debug1 "Processing resumes for external applicants."

# My preference for debug2 calls is to provide function names and input parms.
$ debug2 "process_external_applicant_resumes: $*"

# My preference for debug3 is to provide more detail. These are usually only
# created when I am troubleshooting and often removed later.
$ debug3 "RESUME_NAME=\${RESUME_NAME}" 

# We can show the last 3 lines from the debug log with this command.
$ debug_get 3
DEBUG1   [2017-02-27 08:35:08] 24037: Processing resumes for external applicants.
DEBUG2   [2017-02-27 08:35:11] 24037: process_external_applicant_resumes: 
DEBUG3   [2017-02-27 08:35:14] 24037: RESUME_NAME=John Doe
\`\`\`
Sometimes it is helpful to see our debug output more immediatly. In addition to logging our debug statements we can redirect them to standard out or standard error using the variable shown here.
\`\`\`
# 0 log file only, 1 +standard out, 2 +standard error.
$ export _g_debug_output=2
$ debug1 "This line will be returned to the screen via standard error."
DEBUG1   [2017-02-27 08:42:39] 24037: This line will be returned to the screen via standard error.
\`\`\`
Let's look at the debugd* calls which are meant for supplementary details.
\`\`\`
$ (echo "Hello World";date;echo "Goodbye") | debugd1
! Hello World
! Mon Feb 27 08:45:01 CST 2017
! Goodbye
\`\`\`
All detailed calls read standard input and log it to the log file (or screen in this case) with a "!" beginning each line. This allows you to capture larger quantities of debug details, like file or directory contents, or the output from the "set" command. 

Debug can be enabled at the session level using the debug_start call. Below we will reset our global debug settings and then enable a debug session.
\`\`\`
# Make sure debug calls are not returned to standard out or error in the future.
$ export _g_debug_output=0

# Turn off global debug, although it could be left on.
$ export _g_debug_level=0   

# Start a debug session at level 3.
$ debug_start 3

# Make some debug calls.
$ debug1 "temp=73"
$ debug1 "temp=74"

# Dump the debug buffer to standard out.
$ debug_dump
DEBUG1   [2017-02-27 09:10:43] 24037: temp=73
DEBUG1   [2017-02-27 09:10:52] 24037: temp=74

# Try to dump the buffer again and we can see it is empty until we make more calls.
$ debug_dump
\`\`\`

> Note: Some basic design decisions here are derived from logsna Python library created by Ruslan Spivak. 
> https://github.com/rspivak/logsna

EOF
}

function debug_show {
   # Return status details about current debug settings.
   # >>> debug_show
   ${arcRequireBoundVariables}
   typeset x
   stdout_banner "Debug Settings"
   echo "Log File          : ${_g_debug_file}"
   if [[ -f "${_g_debug_file}" ]]; then
      echo "Size (kb)         : $(file_get_size "${_g_debug_file}")"
   else
      echo "Size (kb)         : 0"
   fi
   echo "Level             : ${_g_debug_level}"
   case ${_g_debug_output} in 
      0) x="Log" ;;
      1) x="Standard Out" ;;
      2) x="Standard Err" ;;
   esac
   echo "Output            : ${x}"
}

function debug_follow {
   # Tail the debug log as a background process. 'fg' to bring to foreground.
   # >>> debug_follow
   tail -f "${_g_debug_file}" &
}

function debug_set_level {
   # Set the debug level, 0 to 3.
   # >>> debug_set_level X
   _g_debug_level=${1:-}
}

function debug_set_log {
   # Set the debug log file.
   # >>> debug_set_log "file"
   file_raise_dir_not_found "$(dirname ${1})" && ${returnFalse} 
   _g_debug_file="${1}"
}

function debug_set_output {
   # Set the debug output location. 0 - File, 1 - STDOUT, 2 - STDERR.
   # >>> debug_set_output X
   _g_debug_output=${1}
}

function debug_truncate {
   # Truncates the debug log file, primarily used during unit testing and development.
   # >>> debug_truncate
   [[ -s "${_g_debug_file}" ]] && cp /dev/null "${_g_debug_file}"
}

function debug_start {
   # Begin a new debug session for the current process.
   # >>> debug_start [debug_level]
   # debug_level: Set the session debug level, 1-3. Default is 3.
   ${arcRequireBoundVariables}
   if (( $# )); then
      _g_debug_session_level=${1}
   else
      _g_debug_session_level=3
   fi
}

function debug_dump {
   # Dump stored debug calls to standard output as reset the storage file.
   # >>> debug_dump [-x]
   # -x: Prevents log file from being truncated/removed subsequent to this call.
   ${arcRequireBoundVariables}
   [[ -s "${_g_debug_session_file}" ]] && cat "${_g_debug_session_file}"
   (( $# == 0 )) && cp /dev/null "${_g_debug_session_file}" 
}

function debug_stop { 
   # End the current debug session and remove buffered lines from the session debug file.
   # >>> debug_stop
   ${arcRequireBoundVariables}
   _g_debug_session_level=0
   [[ -f "${_g_debug_session_file}" ]] && rm "${_g_debug_session_file}"
}

function _debugFormatLogFileEntry {
   # Formats and returns the 3 input values.
   # >>> _debugFormatLogFileEntry "${1}" "${2}" "${3}"
   ${arcRequireBoundVariables}
   printf "${2} [%s] %s %s\n" "${1}" "$(date +'%Y-%m-%d %H:%M:%S')" "${3}"
   ${returnTrue} 
}

function _debug {
   # Write ```string``` to ```_g_debug_file``` if ```debug_level``` of statement is <= to ```_g_debug_level```.
   # >>> _debug "debug_keyword" debug_level" "string"
   # debug_level: The debug level of the string, 1-3.
   # string: The statement to write to the log file.
   ${arcAllowUnboundVariables}
   typeset str debug_level formatted_text debug_keyword
   [[ -z "${_g_debug_file:-}" || -z "${_g_debug_session_file:-}" ]] && return
   _g_debug_level=${_g_debug_level:-0}
   _g_debug_session_level=${_g_debug_session_level:-0}
   debug_keyword="${1}"
   debug_level=${2}  
   str="${3:-}"
   formatted_text=
   if (( ${_g_debug_session_level} )); then
      # Session Log File
      if (( ${debug_level} <= ${_g_debug_session_level} || ${debug_level} == 4 )); then
         [[ -z "${formatted_text:-}" ]] && formatted_text="$(_debugFormatLogFileEntry "$$" "${debug_keyword}${debug_level}" "${str}")"
         _debugWrite 0 "${formatted_text}" "${_g_debug_session_file}" "${str}"
      fi
   elif (( ${debug_level} <= ${_g_debug_level} || ${debug_level} == 4 )); then
      # Global Log File
      formatted_text="$(_debugFormatLogFileEntry "$$" "${debug_keyword}${debug_level}" "${str}")"
      _debugWrite "${_g_debug_output}" "${formatted_text}" "${_g_debug_file}" "${str}"
   fi
}

function _debugd {
   # Writes standard input to the log file using a format for multiple lines/details.
   # >>> _debugd debug_level
   ${arcRequireBoundVariables}
   typeset x debug_level
   debug_level=${1:-1}
   if (( ${_g_debug_session_level} )); then
      if (( ${debug_level} <= ${_g_debug_session_level} || ${debug_level} == 4 )); then
         sed 's/^/! /' >> "${_g_debug_session_file}"
      fi
   elif [[ -n "${_g_debug_file:-}" ]] && (( ${debug_level} <= ${_g_debug_level} )); then
      case ${_g_debug_output} in 
         0) sed "s/^/\[$$\] /" >> "${_g_debug_file}" ;;
         1) sed "s/^/\[$$\] /" | tee -a "${_g_debug_file}" ;;
         2) sed "s/^/\[$$\] /" | tee -a "${_g_debug_file}" 3>&1 1>&2 2>&3 ;;
      esac
   fi
}

function debug0 {
   # Level 0 debug call. These are logged even if debug is not enabled.
   # >>> debug0 "str"
   (( ${debug_module_disabled:-0} )) && ${returnTrue} 
   _debug "DEBUG" 0 "${1}" # DISABLE_FLAG
}

function debug1 {
   # Level 1 debug call.
   # >>> debug1 "X"
   (( ${debug_module_disabled:-0} )) && ${returnTrue} 
   _debug "DEBUG" 1 "${1}" # DISABLE_FLAG
}

function debug2 {
   # Level 2 debug call.
   # >>> debug2 "X"
   (( ${debug_module_disabled:-0} )) && ${returnTrue} 
   _debug "DEBUG" 2 "${1}" # DISABLE_FLAG
}

function debug3 {
   # Level 3 debug call.
   # >>> debug3 "X"
   (( ${debug_module_disabled:-0} )) && ${returnTrue} 
   _debug "DEBUG" 3 "${1:-}" # DISABLE_FLAG
}

function debugd0 {
   # Level 0 "detail" debug call. Reads from standard input.
   # >>> debugd0 ["X"]
   (( ${debug_module_disabled:-0} )) && ${returnTrue} 
   if (( $# )); then
      echo "$*" | _debugd 0
   else 
      cat | _debugd 0
   fi
}

function debugd1 {
   # Level 1 "detail" debug call. Reads from standard input.
   # >>> debugd1 ["X"]
   (( ${debug_module_disabled:-0} )) && ${returnTrue} 
   if (( $# )); then
      echo "$*" | _debugd 1
   else 
      cat | _debugd 1
   fi
}

function debugd2 {
   # Level 2 "detail" debug call. Reads from standard input.
   # >>> debugd2 ["X"]
   (( ${debug_module_disabled:-0} )) && ${returnTrue} 
   if (( $# )); then
      echo "$*" | _debugd 2
   else 
      cat | _debugd 2
   fi
}

function debugd3 {
   # Level 3 "detail" debug call. Reads from standard input.
   # >>> debugd3 ["X"]
   (( ${debug_module_disabled:-0} )) && ${returnTrue} 
   if (( $# )); then
      echo "$*" | _debugd 3
   else 
      cat | _debugd 3
   fi
}

function debug_get {
   # Return last ```X``` lines from the ```_g_debug_file```.
   # >>> debug_get [X]
   # X: Number of lines to return. Defaults to 100.
   if (( $# )); then
      tail -${1} "${_g_debug_file}"
   else
      tail -100 "${_g_debug_file}"
   fi
}

function _debugWrite {
   # Writes text file and optionally return the same to standard out or standard error.
   # >>> _debugWrite "stdout_stderr" "text" "file" 
   # stdout_stderr: Additionally writes to STDOUT when 1 and STDERR in 2.
   # text: Text of debug statement.
   # file: File to write the text to.
   # original_string: String prior to being formatted.
   ${arcRequireBoundVariables}
   typeset stdout_stderr text file original_string
   stdout_stderr="${1:-0}"
   text="${2}"
   file="${3}"
   echo "${text}" >> "${file}" 
   case ${stdout_stderr} in 
      1) echo "${text}" ;;
      2) echo "${text}" 3>&1 1>&2 2>&3 ;;
   esac
}

_g_DebugIsLoaded=1

