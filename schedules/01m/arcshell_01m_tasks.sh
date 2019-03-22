
function __usageArcShell01mTasks {
   cat <<EOF
* Reboot check.
* Monitor alerts and sends recurring notifications when required.
* Monitor the ArcShell message queues.
EOF
} 

arcHome=
. "${HOME}/.arcshell"

# Todo: Add detected downtime duration.
if who -b | str_trim_line -stdin | sort -u | sensor_check -g "arcshell" "check_for_reboot"; then
   sensor_get_last_diff -g "arcshell" "check_for_reboot" | \
      log_warning -stdin -logkey "os" -tags "reboot" "Server Rebooted!"
   sensor_get_last_diff -g "arcshell" "check_for_reboot" | \
      send_message -warning "Server Rebooted!"
   counters_set "os,reboot_count,+1"
fi

alerts_check

msg_check_message_queues

# if [[ -f "${arcLogFile}" ]]; then
#    logmon_read_log -max 1 "${arcLogFile}" | logmon_handle_log -stdin "arcshell_log.cfg" 
# fi

exit 0
