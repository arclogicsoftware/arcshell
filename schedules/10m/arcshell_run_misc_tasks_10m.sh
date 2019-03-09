
function __usageRunMiscTasks10m {
   cat <<EOF
Performs some basic ArcShell house keeping.

Task | About |
-- | -- |
'.tmp' file cleanup | Removes ArcShell .tmp files that are older than 1 day. |
Debug Session file cleanup. | Remove ArcShell debug session files older than 1 day. | 
Track enabled notification groups. | Keep track of the # of enabled notification groups. Log a notice any time is changes.|
Monitor ArcShell files for changes. | Tracks and logs any changes in ArcShell files. | 
EOF
} 

arcHome=
. "${HOME}/.arcshell"

# Purge .tmp files older than 24 hours.
find "${arcTmpDir}/tmp" -type f -mtime +1 -exec rm {} \;

# Purge debug session files older than 24 hours.
find "${arcTmpDir}/_debug" -type f -mtime +1 -exec rm {} \;

# Logs changes when the number of available contact groups changes.
typeset n 
n=$(contact_groups_enabled_count)
counters_set "contact_groups,enabled_count,=${n}"
if echo "There are ${n} contact groups enabled." | \
   sensor_check -group "contact_groups" "contact_groups_enabled_count" ; then
   sensor_get_last_diff -group "contact_groups" "contact_groups_enabled_count" | \
      log_notice -stdin -logkey "contact_groups" "The number of enabled contact groups is now ${n}."
fi

typeset x
x="monitor_arcshell_files_for_changes"
! lock_aquire -try 5 -term 1200 "${x}" && ${exitFalse}
watch_file -tags "arcshell" -look -recurse -exclude "\.git.*|.*user.*tmp.*|\.tar\." -watch "arcshell_files" "${x}"
lock_release "${x}"
