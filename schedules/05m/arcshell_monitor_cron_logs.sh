
function __usageMonitorCronLogFiles {
   cat <<EOF
Monitors the cron log files.
EOF
} 

arcHome=
. "${HOME}/.arcshell"

typeset cron_log
#debug_set_level 3
#debug_set_log "${arcLogDir}/arcshell.log"
while read cron_log; do
   debug3 "Checking ${cron_log} for errors..."
   logmon_read_log -max 10 "${cron_log}" | logmon_handle_log -meta "${cron_log}" -stdin "cron_logs.cfg"
done < <($(config_load_object "file_lists" "cron_logs.cfg"))

exit 0
