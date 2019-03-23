
function __usageMonitorCronLogFiles {
   cat <<EOF
* Monitors cron job output by monitoring log files if configured.
* Monitors crontab file for changes and backs file up anytime a change is detected.
* Uses a counter to track the number of cron jobs.
* Monitors the status of the cron daemon.
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

if crontab -l | sensor_check -group "cron" -log "crontab"; then
   crontab -l > "${arcTmpDir}/crontab_$(dt_ymd_hms)"
   sensor_get_last_diff -group "cron" "crontab" | \
      send_message -notice "A change has been made to the crontab file."
fi      

job_count=$(crontab -l | str_remove_comments -stdin | num_line_count)
counters_set "counter_group,counter,operator,value" 
counters_set "os,cron,cronjob_count,=${job_count}"

typeset sensor_str

if (( $(os_get_process_count "root.*cron") > 0 )); then
   sensor_str="The cron daemon is running."
else
   sensor_str="The cron daemon is **NOT** running."
fi

if echo "${sensor_str}" | sensor_check -group "cron" "cron_daemon"; then
   echo "${sensor_str}" | send_message -warning "${sensor_str}"
fi

exit 0
