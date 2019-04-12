# Schedules

## 01h

### arcshell_01h_tasks.sh

* Collects the size and monitors the size of the ArcShell home directory.
* Removes ArcShell .tmp files that are older than 1 day.
* Remove ArcShell debug session files older than 1 day. 
* Track enabled notification groups.
* Tracks and logs any changes in ArcShell files.

## 01m

### arcshell_01m_tasks.sh

* Reboot check.
* Monitor alerts and sends recurring notifications when required.
* Monitor the ArcShell message queues.

### arcshell_collect_vmstats.sh

Collects server performance metrics using "vmstat".

### arcshell_monitor_server_load.sh

Collects os load metrics and monitor for os load thresholds.

### initial_state_test-dev.sh

## 05m

### arcshell_05m_tasks.sh

* Collects stats for all of the sensor related counters.

### arcshell_monitor_cpu_usage.sh

Collects and monitors server CPU usage and per process CPU usage.

### arcshell_monitor_cron.sh

* Monitors cron job output by monitoring log files if configured.
* Monitors crontab file for changes and backs file up anytime a change is detected.
* Uses a counter to track the number of cron jobs.
* Monitors the status of the cron daemon.

### arcshell_monitor_os_logs.sh

Monitors the operating system log files.

Log File | About |
-- | -- |
/var/log/syslog | Monitored if exists and readable. |
/var/log/syslog.out | "" | 
/var/log/messages | "" | 
dmesg | Monitored for new lines if the program is available. | 
errpt -a | "" |

## 10m

## 20m

### arcshell_monitor_critical_os_files_for_changes.sh

Monitors critical OS files for changes. 

> Modify the targeted directories and files by editing the "critical_os_files" file list under "config".


