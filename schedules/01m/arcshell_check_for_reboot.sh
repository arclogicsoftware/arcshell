
function __usageCheckForReboot {
   cat <<EOF
Logs a warning if a reboot has been detected. Total reboots are counted using a counter.
EOF
} 

arcHome=
. "${HOME}/.arcshell"

boot_is_aux_instance && exit 0
! lock_aquire -try 5 -term 1200 "check_for_reboot" && ${exitFalse}
if who -b | str_trim_line -stdin | sort -u | sensor_check -g "arcshell" "check_for_reboot"; then
   sensor_get_last_diff -g "arcshell" "check_for_reboot" | \
      log_warning -stdin -logkey "os" -tags "reboot" "Reboot Detected!"
   counters_set "os,reboot_count,+1"
   # Todo: Add detected downtime duration.
fi
lock_release "check_for_reboot"

exit 0
