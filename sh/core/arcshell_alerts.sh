
# module_name="Alerting"
# module_about="Easily incorporate recurring alerts and notifications into your scripts."
# module_version=1
# module_image="alarm-clock-1.png"
# copyright_notice="Copyright 2019 Arclogic Software"

_alertsDir="${arcTmpDir}/_arcshell_alerts"
_g_alertTesting=0

mkdir -p "${_alertsDir}"

# ToDo: Stop using "critical" global alert type in testing and use something no one else would use.
# ToDo: Add alerts_report function.

function __readmeAlerting {
   cat <<EOF

# Alerting

**Easily incorporates recurring alerts and notifications into your scripts.**

Use alerts to set up a recurring notifications until a condition is resolved or the alert cycle completes.

Alerts are opened using an alert type. Alerts can be routed to one or more **contact groups** but this is optional as ArcShell will automatically route them to any available group.

Alert types are found in the \`\`\`\${arcHome}/config/alert_types\`\`\` folder.

To change the settings for an alert type copy the alert type file to the \`\`\`\${arcGlobalHome}/config/alert_types\`\`\` folder or \`\`\`\${arcUserHome}/config/alert_types\`\`\` and modify it. 

Alert types can be created by placing new files in one of these two folders. We recommend keeping the number of alert types to a minimum.

Each alert type allows you to configure two alert windows. The initial window and a reminder window. 

Each window is associated with an ArcShell "keyword", an alert count, and an alert interval.

Alert notifications are sent to the ArcShell messaging system with the associated keyword. Please see the ArcShell **keywords** and **messaging** documentation for more.

The initial alert count defines the number of notifications that  occur before moving to the reminder window. The initial alert interval defines the number of minutes between notifications.

Once the settings for the initial and reminder windows are exhausted the alert is automatically closed. If the condition still exists it will likely be re-opened and the cycle will reiterate. 

Alerts can be closed even if they are not open without effect. This makes coding if then else blocks to open and close alerts easy to implement.

**Example of an alert type configuration file.**

\`\`\`
# \${arcHome}/config/alert_types/high.cfg
#
$(cat "${arcHome}/config/alert_types/high.cfg")
\`\`\`

**Example of a keyword configuration file.**

\`\`\`
# \${arcHome}/config/keywords/critical.cfg
#
$(cat "${arcHome}/config/keywords/critical.cfg")
\`\`\`

EOF
}

function __exampleAlerting {
   # Source in ArcShell
   . "${HOME}/.arcshell"

   # Open a 'critical' alert if the cron process is not running.
   if (( $(ps -ef | grep "cron" | grep -v "grep" | num_line_count) == 0 )); then
      alert_open -critical "cron_process_alert" "'cron' process is not running!"
   else
      # Automatically closes alert if it has been opened.
      alert_close "cron_process_alert"
   fi
}

function test_file_setup {
   __setupArcShellAlerting
   alerts_close_all
   _g_alertTesting=1
}

function test_function_setup {
   __setupArcShellAlerting
   (
   cat <<EOF
alert_keyword="critical"
alert_count=2
alert_interval=1
alert_reminder_keyword="warning"
alert_reminder_count=2
alert_reminder_interval=5
EOF
   ) > "${arcGlobalHome}/config/alert_types/critical.cfg"
}

function __setupArcShellAlerting {
   :
}

function _alertsReturnElapsedTime {
   # Return the number of minutes (or seconds when unit testing) that have elapsed since the provided epoch.
   # >>> _alertsReturnElapsedTime "epoch_time"
   ${arcRequireBoundVariables}
   typeset epoch_time
   epoch_time="${1}"
   if (( ${_g_alertTesting} )); then
      dt_return_seconds_since_epoch ${epoch_time}
   else 
      dt_return_minutes_since_epoch ${epoch_time}
   fi
}

function test__alertsReturnElapsedTime {
   typeset n 
   n=$(dt_epoch)
   _alertsReturnElapsedTime ${n} | assert "<2" 
   sleep 4
   _alertsReturnElapsedTime ${n} | assert ">2"
}

function test_alert_open_critical {
   alert_close "test" && pass_test || fail_test 
   ! alert_is_open "test" && pass_test || fail_test 
   alert_open -critical "test" && pass_test || fail_test 
   alert_is_open "test" && pass_test || fail_test 
   ! alert_open -critical "test" && pass_test || fail_test 
}

function test_empty_config_file {
   cp /dev/null "${arcGlobalHome}/config/alert_types/critical.cfg"
   alert_close "test" && pass_test || fail_test 
   ! alert_is_open "test" && pass_test || fail_test 
   alert_open -critical "test" && pass_test || fail_test 
   alert_is_open "test" && pass_test || fail_test 
   ! alert_open -critical "test" && pass_test || fail_test 
   rm "${arcGlobalHome}/config/alert_types/critical.cfg"
}

function alert_open {
   # Open an alert if not open.
   # >>> alert_open [-stdin] [-${alert_type}] [-groups,-g "X,..."] ["alert_id"] "alert_title"
   # -stdin: Reads data from standard input. Alert is only opened when there is data.
   # -group: List of one or more contact groups to route the alert to.
   # alert_id: Option ID for this alert. If not provided a modified form of the title is used.
   # alert_title: Title of the alert. Appears in subject line of any messages.
   # __alert_default_alert_type: Defines the default alert type.
   ${arcRequireBoundVariables}
   debug3 "alert_open: $*"
   typeset alert_id stdin maybeAlertType alert_type alert_id alert_groups
   alert_type="${__alert_default_alert_type:-"high"}"
   alert_groups=
   stdin=
   while (( $# > 0 )); do
      maybeAlertType="${1:1}"
      if config_does_object_exist "alert_types" "${maybeAlertType}.cfg"; then
         alert_type="${maybeAlertType}"
         shift
      fi
      case "${1}" in
         "-stdin") stdin=1 ;;
         "-group"|"-groups"|"-g") shift; alert_groups="-g $(utl_format_single_item_list ${1})" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "alert_open" "(( $# <= 2 ))" "$*" && ${returnFalse}
   _alertRaiseAlertTypeNotFound "${alert_type:-}" && ${returnFalse} 
   alert_id="$(str_to_key_str "${1}")"
   alert_title="${2:-"${alert_id}"}"
   alert_file="${_alertsDir}/${alert_id}.dat"
   if (( ${stdin} )); then
      cat > "${alert_file}"
   else
      # ToDo: If nothing provided include some basic system diag or other here.
      echo "${alert_id}"  > "${alert_file}"
   fi
   # Auto-close alert if no input (OK if alert is not opened).
   if  [[ ! -s "${alert_file}" ]]; then
      alert_close "${alert_id}"
      ${returnFalse} 
   fi
   # Do not open alert if already open.
   alert_is_open "${alert_id}" && ${returnFalse} 
   if cat "${alert_file}" | _alertOpenAlert ${alert_groups} "${alert_type}" "${alert_id}" "${alert_title}"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _alertOpenAlert {
   # Open an alert if not already opened.
   # >>> _alertOpenAlert [-groups,-g "X"] "alert_type" "alert_id" "alert_title"
   ${arcRequireBoundVariables}
   debug3 "_alertOpenAlert: $*"
   typeset _alertGroups _alertFile _alertType _alertID _alertTitle
   _alertGroups=
   _alertType=
   _alertID=
   _alertTitle=
   while (( $# > 0 )); do
      case "${1}" in
         "-group"|"-groups"|"-g") shift; _alertGroups="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "_alertOpenAlert" "(( $# == 3 ))" "$*" && ${returnFalse}
   eval "$(objects_init_object "arcshell_alert")"
   _alertType="${1}"
   _alertID="${2}"
   _alertTitle="${3}"
   _alertFile="${_alertsDir}/${_alertID}.dat"
   eval "$(config_load_all_objects "alert_types" "${_alertType}.cfg")"
   alert_groups="${_alertGroups:-}"
   alert_date="$(date)"
   alert_title="${_alertTitle:-}"
   alert_type="${_alertType}"
   alert_opened=$(dt_epoch)
   alert_keyword="${alert_keyword:-'warning'}"
   alert_count=${alert_count:-24}
   alert_interval=${alert_interval:-60}
   alert_reminder_keyword="${alert_reminder_keyword:-}"
   alert_reminder_count=${alert_reminder_count:-0}
   alert_reminder_interval=${alert_reminder_interval:-60}
   objects_save_temporary_object "arcshell_alert" "${_alertID}" 
   log_terminal "Opening alert '${_alertID}'."
   cat "${_alertFile}" | log_notice -stdin -logkey "alerting" -tags "${_alertID}" "Opening alert." 
   counters_set "alerting,opened,+1"
   counters_set "alerting,opened,${_alertType},+1"
   echo "$(date) Opened [${_alertType}]" >> "${_alertsDir}/${_alertID}.log"
   if alert_send "${_alertID}"; then
      ${returnTrue} 
   else 
      ${returnFalse} 
   fi
}

function _alertRaiseAlertTypeNotFound {
   # Throw error and return true if the alert type is not found.
   # >>> _alertRaiseAlertTypeNotFound "alert_type"
   ${arcRequireBoundVariables}
   typeset alert_type 
   alert_type="${1}"
   if ! config_does_object_exist "alert_types" "${alert_type}.cfg"; then
      log_error -2 -logkey "alerting" "Alert type not found: $*: _alertRaiseAlertTypeNotFound"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _alertIsAlertDue {
   # Return true if the given alert is due.
   # >>> _alertIsAlertDue "alert_id"
   ${arcRequireBoundVariables}
   debug3 "_alertIsAlertDue: $*"
   typeset alert_id active_interval 
   alert_id="${1}"
   eval "$(_alertLoad "${alert_id}")"
   if (( $(_alertReturnsAlertStage "${alert_id}") == 1 )); then
      active_interval=${alert_interval}
   else
      active_interval=${alert_reminder_interval}
   fi
   if (( $(_alertsReturnElapsedTime ${alert_last_sent}) >= ${active_interval} )); then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _alertLoad {
   #
   # >>> eval "$(_alertLoad 'alert_id')"
   ${arcRequireBoundVariables}
   debug3 "_alertLoad: $*"
   typeset alert_id  
   alert_id="${1}"
   echo "$(objects_load_temporary_object "arcshell_alert" "${alert_id}")"
   ${returnTrue} 
}

function _alertReturnsAlertStage {
   # Returns the stage of the alert. First stage is initial config settings and second stage uses "reminder" config.
   # >>> _alertReturnsAlertStage "alert_id"
   ${arcRequireBoundVariables}
   debug3 "_alertReturnsAlertStage: $*"
   typeset alert_id 
   alert_id="${1}"
   eval "$(_alertLoad "${alert_id}")"
   if (( ${alert_sent_count:-0} < ${alert_count:-1} )); then
      debug3 "_alertReturnsAlertStage=1"
      echo 1
   elif (( ${alert_reminder_sent_count:-0} < ${alert_reminder_count:-0} )); then
      debug3 "_alertReturnsAlertStage=2"
      echo 2
   else
      log_error -2 -logkey "alerting" "Could not determine the active keyword for alert '${alert_id}'."
      debug3 "_alertReturnsAlertStage=1"
      echo 1
   fi
}

function _alertCheckAutoCloseAlert {
   # Closes alert and returns true if all notifications have been sent.
   # >>> _alertCheckAutoCloseAlert "alert_id"
   ${arcRequireBoundVariables}
   debug3 "_alertCheckAutoCloseAlert: $*"
   typeset alert_id active_interval
   alert_id="${1}"
   eval "$(_alertLoad "${alert_id}")"
   if (( ${alert_sent_count:-0} > ${alert_count:-1} )) && \
      (( ${alert_reminder_sent_count:-0} > ${alert_reminder_count:-0} )); then
         log_notice -logkey "alerting" -tags "${alert_id}" "Automatically closing alert."
         alert_close "${alert_id}"
         ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function alert_send {
   # Sends the alert to messaging using 'send_message'.
   # >>> alert_send "alert_id"
   ${arcRequireBoundVariables}
   debug3 "alert_send: $*"
   typeset alert_id active_keyword 
   alert_id="${1}"
   eval "$(_alertLoad "${alert_id}")"
   if (( $(_alertReturnsAlertStage "${alert_id}") == 1 )); then
      active_keyword="${alert_keyword}"
      ((alert_sent_count=alert_sent_count+1))
   else 
      active_keyword="${alert_reminder_keyword:-}"
      ((alert_reminder_sent_count=alert_reminder_sent_count+1))
   fi
   if [[ -n "${alert_groups:-}" ]] && (( ${_g_alertTesting} == 0 )); then
      _alertReturnsAlertText "${alert_id}" | send_message -${active_keyword} -groups "${alert_groups}" "${alert_title}"
   else
      _alertReturnsAlertText "${alert_id}" | send_message -${active_keyword} "${alert_title}"
   fi
   alert_last_sent=$(dt_epoch)
   objects_save_temporary_object "arcshell_alert" "${alert_id}" 
   log_terminal "Alert notification sent for '${alert_id}'."
   printf "." >> "${_alertsDir}/${alert_id}.log"
   counters_set "alerting,notifications,+1"
   ${returnTrue} 
}

function _alertReturnsAlertText {
   # Returns the body of the alert message.
   # >>> _alertReturnsAlertText "alert_id"
   # alert_id: Alert ID.
   # __alert_history_line_count: Sets the number of alert history lines that appear in the alert notifcation.
   ${arcRequireBoundVariables}
   debug3 "_alertReturnsAlertText: $*"
   typeset alert_id 
   alert_id="${1}"
   cat <<EOF
$(cat "${_alertsDir}/${alert_id}.dat")

ALERT HISTORY
---------------------
$(cat "${_alertsDir}/${alert_id}.log" | tail -${__alert_history_line_count:-50})
EOF
}

function alert_is_open {
   # Return true an alert is already opened.
   # >>> alert_is_open "alert_id"
   ${arcRequireBoundVariables}
   debug3 "alert_is_open: $*"
   utl_raise_invalid_option "alert_is_open" "(( $# == 1 ))" "$*" && ${returnFalse} 
   typeset alert_id 
   alert_id="$(str_to_key_str "${1}")"
   if objects_does_temporary_object_exist "arcshell_alert" "${alert_id}"; then
      ${returnTrue}  
   else
      ${returnFalse} 
   fi
}

function test_alert_is_open {
   ! alert_is_open "foo" && pass_test || fail_test 
   alert_open -high "foo" && pass_test || fail_test 
   alert_is_open "foo" && pass_test || fail_test 
}

function alert_close {
   # Close an alert.
   # >>> alert_close "alert_id"
   # alert_id: Alert 
   ${arcRequireBoundVariables}
   debug3 "alert_close: $*"
   utl_raise_invalid_option "alert_close" "(( $# == 1 ))" "$*" && ${returnFalse} 
   typeset alert_id
   alert_id="$(str_to_key_str "${1}")"
   if alert_is_open "${alert_id}"; then
      objects_delete_temporary_object "arcshell_alert" "${alert_id}"
      log_terminal "Closing alert '${alert_id}'."
      log_notice -logkey "alerting" -tags "${alert_id}" "Closing alert." 
      touch "${_alertsDir}/${alert_id}.log"
      if tail -1 "${_alertsDir}/${alert_id}.log" | grep "^\." 1> /dev/null; then
         printf "\n" >> "${_alertsDir}/${alert_id}.log"
      fi
      echo "$(date) Closed" >> "${_alertsDir}/${alert_id}.log"
   fi
   # This file can exist even if the alert is not open, so this needs to be
   # outside the if block.
   find "${_alertsDir}" -type f -name "${alert_id}.dat" -exec rm {} \;
   ${returnTrue} 
}

function test_alert_close {
   alert_close "foo" && pass_test || fail_test 
   ! alert_is_open "foo" && pass_test || fail_test 
}

function alerts_list {
   # Return the list of open alert ID's.
   # >>> alerts_list [-l]
   ${arcRequireBoundVariables}
   case "${1:-}" in 
      "-l") _alertsListLong ;;
      *) objects_list_objects "arcshell_alert" ;;
   esac
}

function test_alerts_list {
   alert_open "foo"
   alerts_list | assert_match "^foo$"
   alert_close "foo" 
}

function _alertsListLong {
   # Return long listing of open alerts.
   # >>> _alertsListLong
   ${arcRequireBoundVariables}
   typeset alert_id sent_count
   printf "%-20s %-12s %-6s %-30s\n" "alert_id------------" "type--------" "sent--" "opened------------------------" 
   while read alert_id; do
      eval "$(_alertLoad "${alert_id}")"
      ((sent_count=alert_sent_count+alert_reminder_sent_count))
      printf "%-20s %-12s %-6s %-30s\n" "${alert_id}" "${alert_type}" "${sent_count}" "${alert_date}" 
   done < <(objects_list_objects "arcshell_alert")
}

function alerts_count {
   # Returns the number of open alerts.
   # >>> alerts_count
   alerts_list | num_line_count
}

function alerts_check {
   # Runs through all open alerts and sends them if they are due. Called from a schedule task.
   # >>> alerts_check
   ${arcRequireBoundVariables}
   debug3 "alerts_check: $*"
   typeset alert_id 
   while read alert_id; do
      if _alertIsAlertDue "${alert_id}"; then
         alert_send "${alert_id}"
      fi
   done < <(alerts_list)
   counters_set "alerting,open_alert_count,=$(alerts_count)"
   ${returnTrue} 
}

function alerts_close_all {
   # Close all open alerts.
   # >>> alerts_close_all
   ${arcRequireBoundVariables}
   typeset alert_id 
   while read alert_id; do
      alert_close "${alert_id}"
   done < <(alerts_list)
   ${returnTrue} 
}

function test_alerts_close_all {
   alerts_close_all && pass_test || fail_test 
}

function test_file_teardown {
   rm "${arcGlobalHome}/config/alert_types/critical.cfg"
   _g_alertTesting=0
}

