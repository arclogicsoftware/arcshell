
# module_name="Threshold Monitor"
# module_about="Monitors values based on thresholds combined with time limits."
# module_version=1
# module_image="battery-6.png"
# copyright_notice="Copyright 2019 Arclogic Software"

_thresholdDir="${arcTmpDir}/_arcshell_threshold_monitors" && mkdir -p "${_thresholdDir}"

function __exampleThresholdMonitoring {

   # Input can be a one or two fields. Either "metric|value" or just "value".
   # Input can be more than one line.

   # Monitor OS load average with three different thresholds.
   os_return_load | \
      threshold_monitor \
         -t1 "4,12h,warning" \
         -t2 "14,30m,warning" \
         -t3 "20,0m,critical" \
         "os_load"

   # A configuration file can be used instead.
   os_return_load | \
      threshold_monitor -config "os_load.cfg" "os_load"

   # threshold_monitor can be used like this.
   if os_return_load | threshold_monitor -config "os_load.cfg" "os_load"; then
      # Do something here.
      :
   fi
}

function threshold_monitor {
   # Monitors input for defined thresholds.
   # >>> threshold_monitor [-stdin] [-t1,-t2,-t3 "threshold,duration,['keyword']]" [-config "X"] "threshold_group"
   # -t[1-3]: Threshold, duration (min), and optional keyword.
   # -config: Threshold configuration file. Works with ArcShell config or fixed path.
   # threshold_group: Each set of data piped to this function should be identified as a unique group.
   debug3 "threshold_monitor: $*"
   ${arcRequireBoundVariables}
   typeset threshold_group config_file metric_key metric_value tmpFile \
      enabled_1 enabled_2 enabled_3 \
      threshold_1 threshold_2 threshold_3 \
      keyword_1 keyword_2 keyword_3  \
      return_true_1 return_true_2 return_true_3 \
      duration_min_1 duration_min_2 duration_min_3
   return_true_1=0
   return_true_2=0
   return_true_3=0
   while (( $# > 0)); do
      case "${1}" in
         "-stdin")
            :
            ;;
         "-t1") 
            shift
            IFS="," read threshold_1 duration_min_1 keyword_1 < <(_thresholdsHandleThresholdOption "${1}")
            ;;
         "-t2") 
            shift
            IFS="," read threshold_2 duration_min_2 keyword_2 < <(_thresholdsHandleThresholdOption "${1}")
            ;;
         "-t3") 
            shift
            IFS="," read threshold_3 duration_min_3 keyword_3 < <(_thresholdsHandleThresholdOption "${1}")
            ;;
         "-config")
            shift 
            if [[ -f "${1}" ]]; then
               . "${1}"
            else
               eval "$(config_load_object "threshold_monitors" "${1}")"
            fi
            ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "threshold_monitor" "(( $# == 1 ))" "$*" && ${returnFalse} 
   threshold_group="$(str_to_key_str "${1}")"
   tmpFile="$(mktempf)"
   cat > "${tmpFile}.stdin"
   touch "${_thresholdDir}/thresholds_${threshold_group}.tmp"

   # Threshold 1
   _thresholdRemoveMessageFile
   while IFS="|" read metric_key metric_value; do
      # Handles circumstances when only a value is recieved from standard input.
      [[ -z ${metric_value} ]] && metric_value="${metric_key}" && metric_key="${threshold_group}"
      if is_truthy "${enabled_1:-1}" && [[ -n "${threshold_1:-}" ]]; then
         if _thresholdsEval "${threshold_group}" "${metric_key}_1" "${metric_value}" "${threshold_1}" "${duration_min_1}" "${keyword_1:-}"; then
            return_true_1=1
            counters_set "threshold_monitor,${threshold_group}_1_exceeded,+1"
         else
            counters_set "threshold_monitor,${threshold_group}_1_ok,+1"
         fi
      fi
   done < "${tmpFile}.stdin" >> "${tmpFile}"
   if (( ${return_true_1} )) && [[ -n "${keyword_1:-}" ]]; then
      _thresholdSendMessage "${threshold_group}" "${keyword_1}"
   fi

   # Threshold 2
   _thresholdRemoveMessageFile
   while IFS="|" read metric_key metric_value; do
      # Handles circumstances when only a value is recieved from standard input.
      [[ -z ${metric_value} ]] && metric_value="${metric_key}" && metric_key="${threshold_group}"
      if is_truthy "${enabled_2:-1}" && [[ -n "${threshold_2:-}" ]]; then
         if _thresholdsEval "${threshold_group}" "${metric_key}_2" "${metric_value}" "${threshold_2}" "${duration_min_2}" "${keyword_2:-}"; then
            return_true_2=1
            counters_set "threshold_monitor,${threshold_group}_2_exceeded,+1"
         else
            counters_set "threshold_monitor,${threshold_group}_2_ok,+1"
         fi
      fi
   done < "${tmpFile}.stdin" >> "${tmpFile}"
   if (( ${return_true_2} )) && [[ -n "${keyword_2:-}" ]]; then
      _thresholdSendMessage "${threshold_group}" "${keyword_2}"
   fi

   # Threshold 3
   _thresholdRemoveMessageFile
   while IFS="|" read metric_key metric_value; do
      # Handles circumstances when only a value is recieved from standard input.
      [[ -z ${metric_value} ]] && metric_value="${metric_key}" && metric_key="${threshold_group}"
      if is_truthy "${enabled_3:-1}" && [[ -n "${threshold_3:-}" ]]; then
         if _thresholdsEval "${threshold_group}" "${metric_key}_3" "${metric_value}" "${threshold_3}" "${duration_min_3}" "${keyword_3:-}"; then
            return_true_3=1
            counters_set "threshold_monitor,${threshold_group}_3_exceeded,+1"
         else
            counters_set "threshold_monitor,${threshold_group}_3_ok,+1"
         fi
      fi
   done < "${tmpFile}.stdin" >> "${tmpFile}"
   if (( ${return_true_3} )) && [[ -n "${keyword_3:-}" ]]; then
      _thresholdSendMessage "${threshold_group}" "${keyword_3}"
   fi
   
   mv "${tmpFile}" "${_thresholdDir}/thresholds_${threshold_group}.tmp"
   #debug1 "${_thresholdDir}/thresholds_${threshold_group}.tmp"
   #cat "${_thresholdDir}/thresholds_${threshold_group}.tmp" | debugd1
   if (( ${return_true_1} )) || (( ${return_true_2} )) || (( ${return_true_3} )); then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _thresholdsHandleThresholdOption {
   # Ensures if keyword is not provided that we add a comma so that we return 3 values.
   # >>> _thresholdsHandleThresholdOption "arguments for one of the t[1-3] options"
   ${arcRequireBoundVariables}
   typeset args threshold duration_min keyword
   args="${1}"
   if (( $(str_get_char_count "," "${args}") == 1 )); then
      args="${args},"
   fi
   IFS="," read threshold duration_min keyword < <(echo "${args}")
   if num_is_num "${duration_min}"; then
      duration_min="${duration_min}m"
   fi
   duration_secs=$(dt_return_seconds_from_interval_str "${duration_min}" )
   ((duration_min=duration_min*60))
   echo "${threshold},${duration_min},${keyword}"
   ${returnTrue} 
}

function test__thresholdsHandleThresholdOption {
   typeset x y z
   _thresholdsHandleThresholdOption "1.0,2,warning" | assert_match "1.0,2,warning" "Should return the input unchanged."
   _thresholdsHandleThresholdOption "1.0,2" | assert_match "1.0,2," "Should have added a comma."
   # All fields provided.
   IFS="," read x y z < <(_thresholdsHandleThresholdOption ".2,2.0,notice")
   [[ "${x}" == ".2" ]] && pass_test || fail_test 
   [[ "${y}" == "2.0" ]] && pass_test || fail_test 
   [[ "${z}" == "notice" ]] && pass_test || fail_test 
   # No keyword, has trailing comma.
   IFS="," read x y z < <(_thresholdsHandleThresholdOption ".2,2.0,")
   [[ "${x}" == ".2" ]] && pass_test || fail_test 
   [[ "${y}" == "2.0" ]] && pass_test || fail_test 
   [[ -z "${z:-}" ]] && pass_test || fail_test 
   # No keyword, does not have trailing comma.
   IFS="," read x y z < <(_thresholdsHandleThresholdOption ".2,2.0")
   [[ "${x}" == ".2" ]] && pass_test || fail_test 
   [[ "${y}" == "2.0" ]] && pass_test || fail_test 
   [[ -z "${z:-}" ]] && pass_test || fail_test 
}

function _thresholdRemoveMessageFile {
   find "${_thresholdDir}" -name "thresholds_${threshold_group}.message_file" -exec rm {} \; 
}

function _thresholdsEval {
   #
   # >>> _thresholdsEval "threshold_group" "metric_key" metric_value threshold defined_time_limit keyword
   ${arcRequireBoundVariables}
   debug3 "_thresholdsEval: $*"
   typeset threshold_group metric_key current_value defined_threshold defined_time_limit sensor_mins x sensor_start_time threshold_keyword return_true
   utl_raise_invalid_option "_thresholdsEval" "(( $# == 6 ))" "$*" && ${returnFalse} 
   threshold_group="${1}"
   metric_key="${2}"
   current_value=${3}
   defined_threshold=${4}
   defined_time_limit=${5}
   threshold_keyword="${6:-}"
   return_true=0
   IFS="|" read x sensor_start_time < <(grep "^${metric_key}|.*" "${_thresholdDir}/thresholds_${threshold_group}.tmp")
   [[ -z "${sensor_start_time:-}" ]] && sensor_start_time=0
   #debug1 "current_value=${current_value}"
   if num_is_gt ${current_value} ${defined_threshold}; then
      (( ${sensor_start_time} == 0 )) && sensor_start_time=$(dt_epoch)  
   fi
   #debug1 "sensor_start_time=${sensor_start_time}"
   if (( ${sensor_start_time} > 0 )); then
      sensor_mins=$(dt_return_minutes_since_epoch ${sensor_start_time} )
   else 
      sensor_mins=0
   fi
   #debug1 "sensor_mins=${sensor_mins}; sensor_start_time=${sensor_start_time}"
   if (( ${sensor_mins} > ${defined_time_limit} )); then
      return_true=1
      sensor_start_time=$(dt_epoch)
      (
      cat <<EOF
threshold_group="${threshold_group}"
metric_key="${metric_key}"
defined_threshold=${defined_threshold}
current_value=${current_value}
defined_time_limit=${defined_time_limit}
sensor_mins=${sensor_mins}
threshold_keyword="${threshold_keyword}"
-------------------------------------------------------------------------------
EOF
      ) >> "${_thresholdDir}/thresholds_${threshold_group}.message_file"
   fi
   echo "${metric_key}|${sensor_start_time}"
   if (( ${return_true} )); then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _thresholdSendMessage {
   # Sends the message file using the defined keyword.
   # >>> _thresholdSendMessage "threshold_group" "sensor_keyword"
   debug3 "_thresholdSendMessage: $*"
   typeset threshold_group sensor_keyword
   threshold_group="${1}"
   sensor_keyword="${2}"
   #debug1 "${_thresholdDir}/thresholds_${threshold_group}.message_file"
   #cat "${_thresholdDir}/thresholds_${threshold_group}.message_file" | debugd1
   cat "${_thresholdDir}/thresholds_${threshold_group}.message_file" | \
      send_message -${sensor_keyword} "A threshold in the '${threshold_group}' group has exceeded one of it's limits."
}

