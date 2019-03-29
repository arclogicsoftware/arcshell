#!/bin/bash

. "${HOME}/.arcshell"

function __readmeCronWatch {
   cat <<EOF
# Cron Watch

\`\`\`
# Monitors the exit status each time the job runs.
* * * * * ${HOME}/cron_test.sh 50 1> /dev/null 2>/dev/null ; ${HOME}/cron_check.sh $? "cron_test.sh"
\`\`\`

\`\`\`
# The above can be modified to take advantage of ArcShell built in cron log file monitoring.
* * * * * ${HOME}/cron_test.sh 50 1> /dev/null 2>/dev/null ; ${HOME}/cron_check.sh $? "cron_test.sh"
\`\`\`

EOF
}

typeset job_id status  alert_type keyword 
alert_type=
keyword=
 while (( $# > 0)); do
   case "${1}" in
      "-alert") shift; alert_type="${1}" ;;
      "-keyword") shift; keyword="${1}" ;;
      *) break ;;
   esac
   shift
done
utl_raise_invalid_option "cron_check.sh" "(( $# == 2 ))" "$*" && exit 1
status="${1}"
job_id="$(str_to_key_str "${1}")"
echo "$(dt_epoch) $(dt_y_m_d_h_m_s) ${status} ${job_id}" >> "${arcLogDir}/cron_check.log"
if (( ${status} > 0 )); then
   event_counter_add_event "cron" "E"
   counters_set "os,cron,error_total,+1"
   log_error -logkey "cron" -tags "${job_id}" "cron_check.sh: status=${status}"
   if [[ -n "${keyword:-}" ]]; then
      echo "cron_check.sh: status=${status}" | send_message -${keyword} "Cron job '${job_id}' is returning an error."
   fi
   if [[ -n "${alert_type:-}" ]]; then
      alert_open -${alert_type} "cron_alert_${job_id}" "Cron job '${job_id}' is returning an error."
   fi
else
   event_counter_add_event "cron" "."
   counters_set "os,cron,success_total,+1"
   log_boring -logkey "cron" -tags "${job_id}" "cron_check.sh: status=${status}"
   if [[ -n "${alert_type:-}" ]]; then
      alert_close "cron_alert_${job_id}"
   fi 
fi

exit

