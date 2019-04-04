
# module_name="Timer"
# module_about="Create and manage timers for timing all sorts of things."
# module_version=1
# module_image="stopwatch-1.png"
# copyright_notice="Copyright 2019 Arclogic Software"

[[ -z "${arcTmpDir}" ]] && return
_timerDir="${arcTmpDir}/_arcshell_timers"
mkdir -p "${_timerDir}"

# ToDo: Some functionality is unclear here. Review all for clarity.

function __readmeTimer {
   cat <<EOF
> "Weeks of coding can save you hours of planning." - Anonymous

# Timer

**Create and manage timers for timing all kinds of things.**
EOF
}

function __exampleTimer {
   # Create the timer and start it.
   timer_create -force -start "foo"
   # Do something for 5 seconds.
   sleep 5
   # Should return 5.
   timer_seconds "foo"
   # Do something for 55 seconds.
   sleep 55
   # Should return 1.
   timer_minutes "foo"
   # Stop the timer.
   timer_stop "foo"
   # Starts the timer counting from the point it was stopped at.
   timer_start "foo"
   # End the timer.
   timer_end "foo"
}

function timer_mins_expired {
   # Returns true when timer interval has passed and resets the timer.
   # >>> timer_mins_expired [-inittrue,-i] "timerKey" minutes
   # -inittrue: Forces return of true the first time the timer is created.
   # timerKey: A unique key used to identify the timer.
   # minutes: The number of minutes to wait before expiring and returning true.
   # **Example**
   # ```
   # timer_mins_expired "timerX" 1 && echo Yes || echo No
   # ```
   ${arcRequireBoundVariables}
   typeset timerKey minutes inittrue 
   inittrue=0
   while (( $# > 0)); do
      case "${1}" in
         "-inittrue"|"-i") inittrue=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "timer_mins_expired" "(( $# == 2 ))" "$*" && ${returnFalse} 
   timerKey="${1}"
   minutes=${2}
   if ! timer_exists "${timerKey}"; then
      timer_create -start "${timerKey}" 
      if (( ${inittrue} )); then
         ${returnTrue} 
      else 
         ${returnFalse} 
      fi
   elif (( $(timer_minutes "${timerKey}") >= ${minutes} )); then
      timer_reset "${timerKey}"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test_timer_mins_expired {
   :
}

function timer_secs_expired {
   # Returns true when timer interval has passed and resets the timer.
   # >>> timer_secs_expired [-inittrue,-i] "timerKey" seconds
   # -inittrue: Forces return of true the first time the timer is created.
   # timerKey: A unique key used to identify the timer.
   # seconds: The number of seconds to wait before expiring and returning true.
   # **Example**
   # ```
   # timer_secs_expired "timerX" 10 && echo Yes || echo No
   # ```
   ${arcRequireBoundVariables}
   typeset timerKey seconds inittrue
   inittrue=0
   while (( $# > 0)); do
      case "${1}" in
         "-inittrue"|"-t") inittrue=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "timer_secs_expired" "(( $# == 2 ))" "$*" && ${returnFalse} 
   timerKey="${1}"
   seconds=${2}
   if ! timer_exists "${timerKey}"; then
      timer_create -start "${timerKey}" 
      if (( ${inittrue} )); then
         ${returnTrue} 
      else 
         ${returnFalse} 
      fi
   elif (( $(timer_seconds "${timerKey}") >= ${seconds} )); then
      timer_reset "${timerKey}"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test_timer_secs_expired {
   timer_delete "$$"
   timer_secs_expired "$$" 5 && fail_test "New timer should not return true unless -inittrue is passed." || pass_test 
   assert_sleep 6 
   timer_secs_expired "$$" 5 && pass_test || fail_test "Timer should return true, interval has passed."
   timer_secs_expired "$$" 5 && fail_test "Timer just returned true, should now return false." || pass_test 
   timer_delete "$$"
   timer_secs_expired -inittrue "$$" 5 && pass_test || fail_test "Timer should return true first time called when -inittrue is passed."
   timer_secs_expired -inittrue "$$" 5 && fail_test "Timer should now return false, since it just returned true." || pass_test 
   timer_delete "$$"
}

function _timerRaiseDuplicateTimer {
   # Throw error and return true if the timer already exists.
   # >>> _timerRaiseDuplicateTimer "timerKey" 
   debug3 "_timerRaiseDuplicateTimer: $*"
   ${arcRequireBoundVariables}
   typeset timerKey 
   timerKey="${1}"
   if timer_exists "${timerKey}"; then
      log_error -2 -logkey "timer" -tags "${timerKey}" "Duplicate timer."
      debug3 "_timerRaiseDuplicateTimer: true"
      ${returnTrue}
   else
      debug3 "_timerRaiseDuplicateTimer: false"
      ${returnFalse}
   fi
}

function test__timerRaiseDuplicateTimer {
   timer_delete "$$"
   _timerRaiseDuplicateTimer "$$" && fail_test || pass_test 
   timer_create "$$" && pass_test || fail_test 
   _timerRaiseDuplicateTimer "$$" 2>&1 | assert_match "ERROR"
   _timerRaiseDuplicateTimer "$$" 2>/dev/null && pass_test || fail_test 
   timer_delete "$$" && pass_test || fail_test 
}

function _timerRaiseTimerNotFound {
   # Throw error and return true if the timer does not exist.
   # >>> _timerRaiseTimerNotFound "timerKey" "errorText"
   ${arcRequireBoundVariables}
   typeset timerKey errorText
   timerKey="${1}"
   errorText="${2:-}"
   if ! timer_exists "${timerKey}"; then
      log_error -2 -logkey "timer" -tags "${timerKey}" "Timer not found."
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test__timerRaiseTimerNotFound {
   :
}

function timer_create {
   # Create a new timer. Throws an error if it already exists.
   # >>> timer_create [-force,-f] [-start,-s] [-autolog,-a] ["timerKey"] 
   # -force: Re-create the timer if it already exists.
   # -start: Start timer automatically.
   # -autolog: Logs timer automatically.
   # timerKey: Unique key assigned to the timer. Defaults to current process ID.
   ${arcRequireBoundVariables}
   debug3 "timer_create: $*"
   typeset timerKey timerForce autoStart autoLog
   autoStart=0
   timerForce=0
   autoLog=0
   while (( $# > 0)); do
      case "${1}" in
         "-force"|"-f") timerForce=1 ;;
         "-start"|"-s") autoStart=1 ;;
         "-autolog"|"-a") autoLog=1 ;; 
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "timer_create" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   timerKey="${1:-$$}"
   str_raise_not_a_key_str "timer_create" "${timerKey}" && ${returnFalse}
   (( ${timerForce} )) && timer_delete "${timerKey}"
   _timerRaiseDuplicateTimer "${timerKey}" && ${returnFalse}
   _timerInitTimer "${timerKey}" ${autoLog}
   if (( ${autoStart} )); then
      timer_start "${timerKey}"
   fi
}

function test_timer_create {
   timer_delete "timerOne"
   timer_delete "timerY"
   ! timer_exists "timerOne" && pass_test || fail_test
   timer_create "timerOne" && pass_test || fail_test 
   timer_exists "timerOne" && pass_test || fail_test
   timer_create "timerOne" 2>&1 | assert_match "ERROR" "Should throw duplicate timer error."
   ! timer_exists "timerY" && pass_test || fail_test
   timer_create "timerY" && timer_start "timerY" && pass_test || fail_test 
   timer_exists "timerY" && pass_test || fail_test
   assert_sleep 5
   timer_seconds "timerY" | assert ">3" "Timer should have been running more than 3 seconds."
   
   timer_create 
   timer_exists "$$" && pass_test || fail_test
   timer_delete "$$"
}

function test_timer_autolog {
   timer_delete "timer1" && pass_test || fail_test 
   timer_create -force -autolog -start "timer1" && pass_test || fail_test 
   assert_sleep 2
   log_set_output -1
   timer_stop "timer1" | egrep "DATA" | assert -l 1
   log_set_default
}

function test_timer_create_force {
   timer_delete "timerZ"
   timer_create -f "timerZ" 
   timer_exists "timerZ" && pass_test || fail_test
   timer_create -f "timerZ" 2>&1 >/dev/null | assert -z
   # Will use $$ as the key, does not throw error.
   timer_create -f 2>&1 >/dev/null | assert -z
   p=$$
   timer_exists "${p}" && pass_test || fail_test
   # Again, will use $$ as key. No error.
   timer_delete 2>&1 >/dev/null | assert -z
}

function timer_time {
   # Starts a new timer which will be auto-logged when timer_end if called.
   # >>> timer_time ["timerKey"]
   ${arcRequireBoundVariables}
   typeset timerKey 
   timerKey="${1:-$$}"
   timer_create -force -start -autolog "${timerKey}"
   ${returnTrue} 
}

function timer_end {
   # Used to stop timing a timer started with timer_time.
   # >>> timer_end ["timerKey"]
   ${arcRequireBoundVariables}
   typeset timerKey 
   timerKey="${1:-$$}"
   timer_stop "${timerKey}"
   timer_delete "${timerKey}"
}

function timer_start {
   # Start a new timer or restart an existing timer.
   # >>> timer_start "timerKey"
   ${arcRequireBoundVariables}
   typeset timerKey
   timerKey="${1:-$$}"
   debug3 "timer_start: $*"
   _timerRaiseTimerNotFound "${timerKey}" "timer_start" && ${returnFalse}
   eval "$(_timerLoad "${timerKey}")"
   if [[ "${_timerStatus}" == "Stopped" ]]; then
      _timerStatus="Running"
      _currentIntervalStartTime=$(dt_epoch)
      _timerSave "${timerKey}"
   else
      log_error -2 -logkey "timer" -tags "${timerKey}" "Timer already running."
   fi
}

function test_timer_start {
   timer_create -f "timerOne"
   assert_sleep 2
   timer_seconds "timerOne" | assert 0
   timer_start "timerOne"
   assert_sleep 2
   timer_seconds "timerOne" | assert ">0"
   timer_start 2>&1 | assert_match "ERROR"
   timer_delete "timerOne"
}

function timer_seconds {
   # Return current timer time in seconds. Auto create and start if it doesn't exist.
   # >>> timer_seconds ["timerKey"]
   ${arcRequireBoundVariables}
   typeset timerKey
   timerKey="${1:-$$}"
   if ! timer_exists "${timerKey}"; then
      timer_create -start "${timerKey}" 
   fi
   _timerGet "${timerKey}" "seconds"
}

function test_timer_seconds {
   :
}

function timer_minutes {
   # Return current timer time in minutes. Auto create and start if it doesn't exist.
   # >>> timer_minutes ["timerKey"]
   ${arcRequireBoundVariables}
   typeset timerKey
   timerKey="${1:-$$}"
   if ! timer_exists "${timerKey}"; then
      timer_create -start "${timerKey}" 
   fi
   _timerGet "${timerKey}" "minutes"
}

function test_timer_minutes {
   :
}

function timer_log_timer {
   # Logs the current timer time to the application log.
   # >>> timer_log_timer ["timerKey='$$']
   ${arcRequireBoundVariables}
   typeset timerKey x
   timerKey="${1:-$$}"
   x=$(timer_seconds "${timerKey}")
   log_data -logkey "timer" \
      -tags "timer" \
      "timer_key=\"${timerKey}\";elapsed_seconds=${x}"
}

function test_timer_log_timer {
   timer_create -force -start 
   assert_sleep 3
   log_set_output -1
   timer_log_timer | egrep "DATA" | assert -l 1
   log_set_default
}

function _timerGet {
   # Return total time for timer in seconds or minutes depending on type.
   # >>> _timerGet "timerKey" "timerType"
   # timerKey: 
   # timerType: "minites" or "seconds"
   ${arcRequireBoundVariables}
   debug3 "_timerGet: $*"
   typeset currentTime currentIntervalTime currentTotalTime currentSeconds timerKey timeType
   timerKey="${1:-$$}"
   timeType="${2:-"seconds"}"
   _timerRaiseTimerNotFound "${timerKey}" "_timerGet" && ${returnFalse}
   eval "$(_timerLoad "${timerKey}")"
   currentTime=$(dt_epoch)
   case "${_timerStatus}" in
      "Stopped")
         currentTotalTime=${_totalTimeForCompletedLaps}
         ;;
      "Running")
         currentIntervalTime=$(_timerGetCurrentIntervalTime "${timerKey}")
         ((currentTotalTime=_totalTimeForCompletedLaps+currentIntervalTime))
         ;;
   esac
   if [[ "${timeType}" == "minutes" ]]; then
      currentSeconds=${currentTotalTime}
      ((currentTotalTime=currentTotalTime/60))
   fi
   debug3 "currentTotalTime=${currentTotalTime}, currentSeconds=${currentSeconds:-}"
   echo "${currentTotalTime}"
}

function test_timerGet {
   timer_create -f "timerZ"
   timer_start "timerZ"
   assert_sleep 5
   timer_seconds "timerZ" | assert ">3"
}

function timer_reset {
   # Reset a timer, also starts it if it is not running already.
   # >>> timer_reset ["timerKey"]
   ${arcRequireBoundVariables}
   debug3 "timer_reset: $*"
   typeset timerKey
   timerKey="${1:-$$}"
   eval "$(_timerLoad "${timerKey}")"
   _totalTimeForCompletedLaps=0
   _currentIntervalStartTime=$(dt_epoch)
   _timerStatus="Running"
   _timerSave "${timerKey}"
}

function test_timer_reset {
   timer_delete "timerOne"
   timer_create -f "timerOne"
   timer_start "timerOne"
   assert_sleep 5
   timer_seconds "timerOne" | assert ">4"
   timer_reset "timerOne"
   timer_seconds "timerOne" | assert "<4"
   assert_sleep 5
   timer_seconds "timerOne" | assert ">4"
   timer_delete "timerOne"
}

function timer_stop {
   # Stop a timer.
   # >>> timer_stop "timerKey"
   ${arcRequireBoundVariables}
   typeset currentIntervalTime timerKey
   timerKey="${1:-$$}"
   eval "$(_timerLoad "${timerKey}")"
   debug3 "timer_stop: $*"
   if [[ "${_timerStatus}" == "Running" ]]; then
      _timerStatus="Stopped"
      currentIntervalTime=$(_timerGetCurrentIntervalTime "${timerKey}")
      ((_totalTimeForCompletedLaps=_totalTimeForCompletedLaps+currentIntervalTime))
      _currentIntervalStartTime=0
      _timerSave "${timerKey}"
      if (( ${_timerAutoStart} )); then
         timer_log_timer "${timerKey}"
      fi
   else
      log_error -2 -logkey "timer" -tags "${timerKey}" "Timer already stopped."
   fi
}

function test_timer_stop {
   timer_create -f "laps"
   timer_start "laps"
   assert_sleep 2
   timer_stop "laps"
   assert_sleep 4
   timer_seconds "laps" | assert "<4"
   timer_start "laps"
   assert_sleep 4
   timer_seconds "laps" | assert ">5"
   timer_delete "laps"
}

function timer_delete {
   # Delete a timer.
   # >>> timer_delete "timerKey"
   ${arcRequireBoundVariables}
   typeset timerKey
   timerKey="${1:-$$}"
   debug3 "timer_delete: $*"
   str_raise_not_a_key_str "timer_delete" "${timerKey}" && ${returnFalse} 
   if timer_exists "${timerKey}"; then
      rm "${_timerDir}/${timerKey}"
   fi
   ${returnTrue} 
}

function test_timer_delete {
   assert_sleep 60
   timer_seconds "timerY" | assert ">0"
   timer_create -f "timerOne"
   timer_exists "timerOne" && pass_test || fail_test
   timer_delete "timerOne" 
   ! timer_exists "timerOne" && pass_test || fail_test
   # Timer key will default to $$ if not provided.
   timer_delete 2>&1 | assert -z
   timer_delete "timerY"
}

function _timerInitTimer {
   # Initialize variables stored in the data file before creating a new timer.
   # >>> _timerInitTimer "timerKey" "autoStart"
   ${arcRequireBoundVariables}
   typeset timerKey autoStart
   timerKey="${1}"
   autoStart="${2}"
   _timerStatus="Stopped"
   _totalTimeForCompletedLaps=0
   _currentIntervalStartTime=0
   _timerAutoStart=${autoStart}
   _timerSave "${timerKey}" 
}

function _timerLoad {
   # Loads the timer variables into the current functions shell.
   # >>> eval "$(_timerLoad "timerKey")"
   # timerKey: 
   ${arcRequireBoundVariables}
   debug3 "_timerLoad: $*"
   typeset timerKey
   timerKey="${1}"
   cat "${_timerDir}/${timerKey}" | debugd3
   echo ". ${_timerDir}/${timerKey}"
}

function _timerSave {
   # Save the current environment variables to the data file.
   # >>> _timerSave "timerKey"
   # timerKey:
   ${arcRequireBoundVariables}
   typeset timerKey
   debug3 "_timerSave: $*"
   timerKey="${1}"
   (
   cat <<EOF
_timerStatus="${_timerStatus}"
_totalTimeForCompletedLaps=${_totalTimeForCompletedLaps:-0}
_currentIntervalStartTime=${_currentIntervalStartTime:-}
_timerAutoStart=${_timerAutoStart:-0}
EOF
   ) > "${_timerDir}/${timerKey}"
   
}

function timer_exists {
   # Return true if timer exists.
   # >>> timer_exists "timerKey"
   debug3 "timer_exists: $*"
   ${arcRequireBoundVariables}
   typeset timerKey
   timerKey="${1:-}"
   str_raise_not_a_key_str "timer_exists" "${timerKey}" && ${returnFalse} 
   if [[ -f "${_timerDir}/${timerKey}" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_timer_exists {
   ! timer_exists "does_not_exist" && pass_test || fail_test
   timer_create -f "timerOne"
   timer_exists "timerOne" && pass_test || fail_test
   timer_exists 2>&1 | assert_match "ERROR"
   timer_delete "timerOne"
}

function _timerGetCurrentIntervalTime {
   # Return number of seconds for current interval.
   # >>> _timerGetCurrentIntervalTime "timerKey"
   ${arcRequireBoundVariables}
   typeset timerKey currentTime currentIntervalTime
   timerKey="${1:-$$}"
   eval "$(_timerLoad "${timerKey}")"
   currentTime=$(dt_epoch)
   ((currentIntervalTime=currentTime-_currentIntervalStartTime))
   echo ${currentIntervalTime}
}

function test__timerGetCurrentIntervalTime {
   timer_create -f "timerFour"
   timer_start "timerFour"
   assert_sleep 5
   _timerGetCurrentIntervalTime "timerFour" | assert ">3"
}

