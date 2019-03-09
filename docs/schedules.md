# Schedules

## 01h

### arcshell_hourly_tasks.sh

## 01m

### arcshell_check_alerts.sh

Monitor alerts and send recurring notifications when required.

### arcshell_check_for_reboot.sh

Logs a warning if a reboot has been detected. Total reboots are counted using a counter.

### arcshell_check_message_queues.sh

Checks the message queues and sends queued messages when set criteria is met.

### arcshell_collect_server_load.sh

Collects server load metrics.

### arcshell_collect_vmstats.sh

Collects server performance metrics using "vmstat".

### arcshell_monitor_cpu_usage.sh

Collects and monitors server CPU usage.

## 05m

### arcshell_monitor_os_logs.sh

Monitors the operating system log files.

Log File | About |
-- | -- |
/var/log/syslog | Monitored if exists and readable. |
/var/log/syslog.out | "" | 
/var/log/messages | "" | 
dmesg | Monitored for new lines if the program is available. | 
errpt -a | "" |

### arcshell_run_misc_tasks_05m.sh

## 10m

### arcshell_run_misc_tasks_10m.sh

Performs some basic ArcShell house keeping.

Task | About |
-- | -- |
'.tmp' file cleanup | Removes ArcShell .tmp files that are older than 1 day. |
Debug Session file cleanup. | Remove ArcShell debug session files older than 1 day. | 
Track enabled notification groups. | Keep track of the # of enabled notification groups. Log a notice any time is changes.|
Monitor ArcShell files for changes. | Tracks and logs any changes in ArcShell files. | 

## 20m

### arcshell_monitor_critical_os_files_for_changes.sh

Monitors critical OS files for changes. 

> Modify the targeted directories and files by editing the "critical_os_files" file list under "config".


