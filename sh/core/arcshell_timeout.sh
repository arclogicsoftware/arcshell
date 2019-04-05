
# module_name="Timeout"
# module_about="Implement timeouts to kill hung processes and perform other time dependent tasks."
# module_version=1
# module_image="hourglass.png"
# copyright_notice="Copyright 2019 Arclogic Software"

# VirtualBox Windows mounted drives have issues, we need to use /tmp.
#_timeoutsDir="${arcTmpDir}/_arcshell_timeouts"
_timeoutsDir="/tmp/${LOGNAME}/arcshell/_arcshell_timeouts"
mkdir -p "${_timeoutsDir}" && chmod 700 "${_timeoutsDir}"

function __readmeTimeout {
   cat <<EOF
> Though a program be but three lines long, someday it will have to be maintained. -- The Tao Of Programming 

# Timeout

**Implement timeouts to kill hung processes and perform other time dependent tasks.**
EOF
}

function test_file_setup {
   __setupArcShellTimeout
}

function __setupArcShellTimeout {
   _timeoutRebuildTimeoutsDir
}

function _timeoutRebuildTimeoutsDir {
   # Purges any orphaned files by rebuilding the temp directory.
   ${arcRequireBoundVariables}
   rm -rf "{_timeoutsDir}"
   mkdir -p "${_timeoutsDir}"
}

function timeout_set_timer {
   # Create a new timeout timer.
   # >>> timeout_set_timer "timerKey" [timerSeconds=60]
   # timerKey: Key string used to identify timer.
   # timerSeconds: Number of seconds on the timer.
   ${arcRequireBoundVariables}
   typeset timerKey 
   timerKey="${1}"
   timeout_delete_timer "${timerKey}"
   eval "$(objects_init_object "arcshell_timeout_timer")"
   __timeoutSeconds=${2:-60}
   if ! timeout_exists "${timerKey}"; then
      __timeoutStartEpoch=$(dt_epoch)
      ((__timeoutEndEpoch=__timeoutStartEpoch+__timeoutSeconds))
      _timeoutSave "${timerKey}"
      _timeoutGenerateScript "${timerKey}"
      _timeoutExecuteScript "${timerKey}"
   else
      _timeoutThrowError "Timer already exists: $*: timeout_set_timer"
   fi
}

function test_timeout_set_timer {
   timeout_delete_timer "foo" && pass_test || fail_test 
   assert_false "timeout_exists "foo"" "Timer should not exist after it has been deleted."
   timeout_set_timer "foo" 10 && pass_test || fail_test 
   assert_true "timeout_exists "foo"" "Timer should exist after it is created."
}

function timeout_delete_timer {
   # Delete a timer.
   # >>> timeout_delete_timer "timerKey"
   ${arcRequireBoundVariables}
   typeset timerKey timerProcessId
   timerKey="${1}"
   if timeout_exists "${timerKey}"; then
      objects_delete_temporary_object "arcshell_timeout_timer" "${timerKey}"
   fi
   timerProcessId=$(_timeoutReturnPid "${timerKey}")
   if (( ${timerProcessId} > 0 )); then
      # bash shell will show 'sleep' as the process, other shells will show the timer key.
      if (( $(ps -ef | grep "${timerProcessId}" | egrep "sleep|${timerKey}" | grep -v "grep" | wc -l) > 0 )); then
         kill -9 ${timerProcessId}
      fi
   fi
   _timeoutRemoveFiles "${timerKey}"
}

function test_timeout_delete_timer {
   timeout_delete_timer "foo"
   assert_false "timeout_exists "foo"" "Deleted timer does not exist."
}

function _timeoutReturnPid {
   # Return the process ID of the timer.
   # >>> _timeoutReturnPid "${timerKey}"
   ${arcRequireBoundVariables}
   typeset timerKey timerProcessId
   timerKey="${1}"
   timerProcessId=0
   if [[ -f "${_timeoutsDir}/${timerKey}pid" ]]; then
      timerProcessId="$(cat "${_timeoutsDir}/${timerKey}pid")"
   fi
   echo ${timerProcessId}
}

function test__timeoutReturnPid {
   _timeoutReturnPid "foo" | assert 0 "Before setting timer PID should be zero."
   timeout_set_timer "foo" 10 && pass_test || fail_test 
   _timeoutReturnPid "foo" | assert ">0" "After setting timer PID should be greater than zero."
}

function _timeoutRemoveFiles {
   # Remove all files related to a timer.
   # >>> _timeoutRemoveFiles "timer_key"
   ${arcRequireBoundVariables}
   typeset timerKey 
   timerKey="${1}"
   find "${_timeoutsDir}" -name "${timerKey}*" -exec rm -f {} \;
   ${returnTrue} 
}

function test__timeoutRemoveFiles {
   timeout_delete_timer "foo" && pass_test || fail_test 
   find "${_timeoutsDir}" -type f -name "foo*" | assert -l 0 "There should not be any files matching foo*."
   timeout_set_timer "foo" 10 && pass_test || fail_test 
   find "${_timeoutsDir}" -type f -name "foo*" | wc -l | assert ">0" "There should be at least one timer file."
   _timeoutRemoveFiles "foo" && pass_test || fail_test 
   find "${_timeoutsDir}" -type f -name "foo*" | assert -l 0 "There should not be any timer files."
   timeout_delete_timer "foo" && pass_test || fail_test 
}

function _timeoutGenerateScript {
   # Generates the timer script.
   # >>> _timeoutGenerateScript "timerKey"
   ${arcRequireBoundVariables}
   typeset timerKey
   timerKey="${1}"
   eval "$(_timeoutsLoadTimer "${timerKey}")"
   (
   cat <<EOF
arcHome=
. ~/.arcshell
sleep ${__timeoutSeconds}
timeout_delete_timer ${timerKey}
_timeoutThrowError "Timer Has Expired: ${timerKey}"
exit 1
EOF
   ) > "${_timeoutsDir}/${timerKey}"
}

function _timeoutExecuteScript {
   # Executes the timer script.
   # >>> _timeoutExecuteScript "timerKey"
   ${arcRequireBoundVariables}
   typeset timerKey x
   timerKey="${1}"
   chmod 700 "${_timeoutsDir}/${timerKey}"
   x="$(pwd)"
   cd "${_timeoutsDir}"
   "./${timerKey}" &
   echo $! > "${_timeoutsDir}/${timerKey}pid"
   cd "${x}"
}

function _timeoutSave {
   # Save a timer.
   ${arcRequireBoundVariables}
   typeset timerKey
   timerKey="${1}"
   objects_save_temporary_object "arcshell_timeout_timer" "${timerKey}"
}

function _timeoutsLoadTimer {
   # Load a timer.
   # eval "$(_timeoutsLoadTimer "timerKey")"
   ${arcRequireBoundVariables}
   typeset timerKey
   timerKey="${1}"
   echo "$(objects_load_temporary_object "arcshell_timeout_timer" "${timerKey}")"
}

function timeout_exists {
   # Return true if the timer exists.
   # >>> timeout_exists "timerKey"
   ${arcRequireBoundVariables}
   typeset timerKey
   timerKey="${1}"
   if objects_does_temporary_object_exist "arcshell_timeout_timer" "${timerKey}"; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function _timeoutThrowError {
   # Throw error to standard out.
   # >>> _timeoutThrowError "error_message"
   throw_error "arcshell_timeout.sh" "${1}"
}
