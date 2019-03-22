
function __usageMonitorCpuUsage {
   cat <<EOF
Collects and monitors server CPU usage and per process CPU usage.
EOF
} 

arcHome=
. "${HOME}/.arcshell"

boot_is_aux_instance && exit 0

typeset cpu_pct_used 
# Sleep so we miss the spin cpu testing.
sleep 40
cpu_pct_used="$(os_return_cpu_pct_used)"

# Monitors CPU used for the node.
echo "${cpu_pct_used}" | threshold_monitor -config "cpu_thresholds.cfg" "cpu_thresholds"

# Monitors CPU at the per/process level.
os_return_process_cpu_seconds | \
   awk -F"|" '{print $1"_"$3"_"$4"|"$2}' | \
   grep -v "|0$" | \
   stats_read -minute -1 -donottrack "cpu_process_thresholds" | \
   threshold_monitor -config "cpu_process_thresholds.cfg" "cpu_process_thresholds"

exit 0

