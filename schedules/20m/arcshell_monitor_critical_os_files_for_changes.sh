
function __usageMonitorCriticalOSFilesForChanges {
   cat <<EOF
Monitors critical OS files for changes. 

> Modify the targeted directories and files by editing the "critical_os_files" file list under "config".

EOF
} 

arcHome=
. "${HOME}/.arcshell"

boot_is_aux_instance && exit 0

! is_truthy "${monitor_critical_os_files_for_changes:-0}" && exit 0

typeset x
x="monitor_critical_os_files_for_changes"
! lock_aquire -try 5 -term 1200 "${x}" && ${exitFalse}
timer_time "watching_critical_os_files"
watch_file -hash -tags "security,os" -watch "critical_os_files.cfg" "${x}"
timer_end "watching_critical_os_files"
lock_release "${x}"

exit 0
