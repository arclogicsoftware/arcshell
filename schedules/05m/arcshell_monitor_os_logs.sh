
function __usageMonitorOSLogs {
   cat <<EOF
Monitors the operating system log files.

Log File | About |
-- | -- |
/var/log/syslog | Monitored if exists and readable. |
/var/log/syslog.out | "" | 
/var/log/messages | "" | 
dmesg | Monitored for new lines if the program is available. | 
errpt -a | "" |
EOF
} 

arcHome=
. "${HOME}/.arcshell"

boot_is_aux_instance && exit 0

! lock_aquire -try 5 -term 1200 "monitor_os_logs" && ${exitFalse}

if [[ -r "/var/log/syslog" ]]; then
   log_boring -logkey "os" -tags "logs" "Monitoring /var/log/syslog file."
   logmon_read_log -max 10 "/var/log/syslog" | logmon_handle_log -stdin "var_log_syslog"
fi

if [[ -r "/var/log/syslog.out" ]]; then
   log_boring -logkey "os" -tags "logs" "Monitoring /var/log/syslog.out file."
   logmon_read_log -max 10 "/var/log/syslog.out" | \
      logmon_handle_log -stdin "var_log_syslog"
fi

if [[ -r "/var/log/messages" ]]; then
   log_boring -logkey "os" -tags "logs" "Monitoring /var/log/messages file."
   logmon_read_log -max 10 "/var/log/messages" | logmon_handle_log -stdin "var_log_messages"
fi

if boot_is_program_found "dmesg"; then
   log_boring -logkey "os" -tags "logs" "Monitoring dmesg."
   dmesg | sensor -new "dmesg_sensor" | logmon_handle_log -stdin "var_log_dmesg"
fi

if boot_is_program_found "errpt"; then
   log_boring -logkey "os" -tags "logs" "Monitoring errpt -a."
   errpt -a | sensor -new "errpt_sensor" | logmon_handle_log -stdin "var_log_errpt"
fi

lock_release "monitor_os_logs"

exit 0
