
function __usageMonitorCpuUsage {
   cat <<EOF
Collects and monitors server CPU usage.
EOF
} 

arcHome=
. "${HOME}/.arcshell"

boot_is_aux_instance && exit 0

typeset cpu_usage cpu_text
cpu_text="CPU usage is being monitored." 
cpu_keyword="notice"
# Sleep so we miss the spin cpu testing.
sleep 35
cpu_usage="$(os_return_cpu_usage)"

if (( ${cpu_usage} > 0 )); then
   log_info "CPU usage is ${cpu_usage}%."
   if (( $(timer_minutes "cpu90") > 60 )); then
      cpu_text="CPU usage has exceeded 90% for $(timer_minutes "cpu90") minutes."
      cpu_keyword="warning"
      timer_delete "cpu90"
   fi
else
   timer_delete "cpu90"
fi

if (( ${cpu_usage} > 50 )); then
   log_info "CPU usage is ${cpu_usage}%."
   if (( $(timer_minutes "cpu50") > 600 )); then
      cpu_text="CPU usage has exceeded 50% for $(timer_minutes "cpu50") minutes."
      cpu_keyword="warning"
      timer_delete "cpu50"
   fi
else
   timer_delete "cpu50"
fi

echo "${cpu_text}" | \
   sensor -group "os" -tags "cpu" -log "cpu_usage" | \
   send_message -keyword "${cpu_keyword}" "CPU Usage"

exit 0

