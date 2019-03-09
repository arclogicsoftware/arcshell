#!/bin/bash

# Force a reload here. 'ksh' was not seeing some functions unless we force
# reload. Prob. related to coming from bash shell and arcHome set but 
# functions not exported. No big deal, just do the reload.

arcHome=
. "${HOME}/.arcshell"

function __todoArcShellDaemon {
   cat <<EOF
* Add uptime reporting.
* Add downtime reporting when restarting.
* Add -force option where needed.
* Add suspend time limit.
EOF
}

typeset _g_arcshellStartDaemon x process_count total_line_count last_line_count number_of_new_lines c

_g_arcshellStartDaemon=0

[[ ! -d "${arcHome}" ]] && exit 1

function _arcshellClientUsage {
   cat <<EOF

arcshell.sh  [-help] [-debug X] [option]

-help       Run help.
-debug      Set the debug level (1-3).
start       Starts daemon. Does nothing is already started.
autostart   Restarts deamon if stopped unexpectedly.
stop        Stops daemon. This can take up to 60 seconds.
restart     Stops and starts the daemon.
status      Returns 'started', 'suspended', or 'stopped'.
kill        Kills daemon if it is running.
suspend     Puts daemon is suspend status. Stops daemon if started.
resume      Restores the daemon to the state prior to being suspended.

EOF
}

if (( $# == 0 )) || [[ "${1:-}" == "-help" ]] || [[ "${1:-}" == "-h" ]]; then
   _arcshellClientUsage
   exit 0
fi

function _arcshellSuspendDaemon {
   # Stops the daemon if it is running and puts it in suspend status.
   # >>> _arcshellSuspendDaemon
   ${arcRequireBoundVariables}
   if arc_is_daemon_running; then
      _arcshellStopDaemon
      flag_set "daemon_suspended" "restart"
      log_boring -logkey "arcshell.sh" -tags "daemon,suspend" "Daemon is suspended."
   elif [[ "$(flag_get "daemon_suspended")" != "no" ]]; then
      log_error -2 -logkey "arcshell.sh" "Daemon is already suspended: suspend: arcshell.sh"
   else
      log_boring -logkey "arcshell.sh" -tags "daemon,suspend" "Daemon is suspended."
      flag_set "daemon_suspended" "yes"
   fi
   ${returnTrue} 
}

function _arcshellResumeDaemon {
   # Starts the daemon process if it is not running and in suspended status.
   # >>> _arcshellResumeDaemon
   ${arcRequireBoundVariables}
   if arc_is_daemon_running; then
      log_error -2 -logkey "arcshell.sh" "Daemon is already running: resume: arcshell.sh" 
   elif [[ "$(flag_get "daemon_suspended")" == "yes" ]]; then
      log_boring -logkey "arcshell.sh" -tags "daemon,resume" "Daemon is no longer suspended."
   elif [[ "$(flag_get "daemon_suspended")" == "restart" ]]; then
      log_boring -logkey "arcshell.sh" -tags "daemon,resume" "Daemon is no longer suspended."
      _g_arcshellStartDaemon=1
   elif [[ "$(flag_get "daemon_suspended")" == "no" ]]; then
      log_error -2 -logkey "arcshell.sh" "Daemon is not suspended: resume: arcshell.sh"
   fi
   flag_set "daemon_suspended" "no"
   ${returnTrue} 
}

function _arcshellKillDaemon {
   # Kill -9 the ArcShell daemon process if it is still running.
   # >>> _arcshellKillDaemon
   ${arcRequireBoundVariables}
   typeset p 
   p=$(_arcshellGetDaemonProcessId)
   log_boring -logkey "arcshell.sh" -tags "daemon,kill" "Daemon process ${p} will be killed..."
   kill -9 ${p}
   rm "${arcTmpDir}/daemon.pid"
}

function _arcshellStopDaemon {
   # Wait for the daemon to exit the execution loop and then stop.
   # >>> _arcshellStopDaemon
   ${arcRequireBoundVariables}
   typeset x
   x=$(dt_seconds_remaining_in_minute)
   log_boring "Daemon process $(_arcshellGetDaemonProcessId) will stop in ${x} seconds..."
   rm "${arcTmpDir}/daemon.pid"
   sleep ${x}
}

function _arcshellGetDaemonStatus {
   # Return the current textual status of the ArcShell daemon.
   # >>> _arcshellGetDaemonStatus
   ${arcRequireBoundVariables}
   if arc_is_daemon_running; then
      echo "started"
   elif arc_is_daemon_suspended; then
      echo "suspended"
   elif [[ -f "${arcTmpDir}/daemon.pid" ]]; then
      echo "down"
   else
      echo "stopped"
   fi
}

if ! flag_exists "daemon_suspended"; then
   flag_set "daemon_suspended" "no"
fi

# Getting rid of the need for this but if already in use don't break.
[[ "${1:-}" == "daemon" ]] && shift 

while (( $# > 0 )); do
   case "${1:-}" in 
      "-debug")
         shift
         debug_set_level ${1}
         ;;
      "start")
         if ! arc_is_daemon_running; then
            _g_arcshellStartDaemon=1
         fi
         ;;
      "autostart")
         if [[ "$(_arcshellGetDaemonStatus)" == "down" ]]; then
            log_notice -logkey "arcshell" -tags "daemon,autostart" "Daemon is being started with autostart."
            _g_arcshellStartDaemon=1
         fi
         ;;
      "stop") 
         if arc_is_daemon_running; then
            _arcshellStopDaemon
         else 
            log_error -2 -logkey "arcshell.sh" "Daemon is not running: $*: arcshell.sh"
         fi
         ;;
      "restart")
         arcshell.sh daemon stop
         _g_arcshellStartDaemon=1
         ;;
      "kill")
         if arc_is_daemon_running; then
            _arcshellKillDaemon
         else 
            log_error -2 -logkey "arcshell.sh" "Daemon is not running: $*: arcshell.sh"
         fi
         ;;
      "status")
         _arcshellGetDaemonStatus
         ;;
      "suspend")
         _arcshellSuspendDaemon
         ;;
      "resume")
         _arcshellResumeDaemon 
         ;;
      *)
         log_error -2 -logkey "arcshell.sh" "Invalid option: ${1:-}: arcshell.sh"
         exit 1
         ;;
   esac
   shift
done

(( ! ${_g_arcshellStartDaemon} )) && exit 0 

echo $$ > "${arcTmpDir}/daemon.pid"

arcHome=
. "${HOME}/.arcshell"

if [[ "$(flag_get "daemon_suspended")" != "no" ]]; then
   log_error -2 -logkey "arcshell.sh" "Daemon is suspended: $*: arcshell.sh"
   ${exitFalse}
fi

flag_set "daemon_suspended" "no"

timer_create -force -start -autolog "arcshell_daemon"

if is_tty_device; then
   log_error -2 -logkey "arcshell.sh" "Can't start the daemon from a tty device. Use 'nohup'!"
   ${exitFalse}
fi

cp /dev/null "${HOME}/arcshell.err"

typeset process_count

(
process_count=0
while (( 1 )); do

   if (( $(_arcshellGetDaemonProcessId) != $$ )); then 
      break
   fi

   process_count=$(_arcReturnArcShellProcessCount)

   log_boring -logkey "arcshell.sh" -tags "daemon" "Daemon process $$ is running. ${process_count} processes are running."
   
   if (( ${process_count} > ${arcshell_process_count_shutdown:-350} )); then
      log_error -2 -logkey "arcshell.sh" "ArcShell process count (${process_count}) is too high! Killing processes and shutting down!" 
      nohup "${arcUserHome}/arcshell.sh" daemon kill &
      break
   fi

   if (( ${process_count} > ${arcshell_process_count_warning:-200} )); then 
      log_error -2 -logkey "arcshell.sh" "ArcShell process count (${process_count}) may be too high."
   fi

   if (( ${process_count} > ${arcshell_process_count_max:-275} )); then
      log_error -2 -logkey "arcshell.sh" "Max process count (${arcshell_process_count_max:-999}) exceeded." 
   else
      arcshell_check_schedules
      counters_update
      process_count=$(_arcReturnArcShellProcessCount)
   fi

   c=$(file_line_count "${HOME}/arcshell.err")
   [[ -z "${total_line_count:-}" ]] && total_line_count=${c}
   last_line_count="${total_line_count}"
   total_line_count=${c}
   ((number_of_new_lines=total_line_count-last_line_count))

   counters_set "arcshell_daemon,process_count,=${process_count}" 
   counters_set "arcshell_daemon,error_count,=${total_line_count}"
   counters_set "arcshell_daemon,uptime_minutes,=$(timer_minutes "arcshell_daemon")"
   counters_set "arcshell_daemon,epoch_seconds,=$(dt_epoch)"

   if (( ${number_of_new_lines} )); then
      tail -${number_of_new_lines} "${HOME}/arcshell.err" | \
         log_error -stdin -logkey "arcshell.sh" -tags "daemon" 
   fi

   x=$(dt_seconds_remaining_in_minute)
   ! num_is_num ${x} && break
   ((x=x+1))
   sleep ${x}
   
done
log_boring -logkey "arcshell.sh" -tags "daemon" "Daemon process $$ is terminated."
) 1>> "${arcLogDir}/arcshell.out" 2>> "${arcErrFile}"

exit 0

