
function __usageCollectVmstats {
   cat <<EOF
Collects server performance metrics using "vmstat".
EOF
} 

arcHome=
. "${HOME}/.arcshell"

boot_is_aux_instance && exit 0
! lock_aquire -try 5 -term 1200 "collect_vmstats" && ${exitFalse}
os_return_vmstat 10 | stats_read "vmstats" 
lock_release "collect_vmstats"

exit 0
