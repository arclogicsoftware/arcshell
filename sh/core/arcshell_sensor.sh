

# module_name="Sensors"
# module_about="Detects changes or things that have not changed."
# module_version=1
# module_image="compass.png"
# copyright_notice="Copyright 2019 Arclogic Software"

_sensorHome="${arcTmpDir}/_arcshell_sensors" && mkdir -p "${_sensorHome}"
_sensorTestFile="${arcTmpDir}/sensor$$.test"

function _sensorTasks {
   stats_read_counter_group -v -t "sensors" "sensors"
}

function sensor_check {
   # Return true if a sensor is triggered otherwise return false.
   # This type of check does not return output.
   # >>> sensor_check [-group,-g "X"] [-try,-t X] [-new,-n] [-tags "X"] [-log,-l] "sensor_key"
   # -group: The sensor group.
   # -try: Try X times before triggering sensor.
   # -new: Detect new input lines only.
   # -tags: Comma separated list of tags. One word each. Will be written to log if enabled.
   # -log: Logs sensor data when triggered.
   # sensor_key: Unique string within a group which identifies a sensor.
   ${arcRequireBoundVariables}
   typeset sensor_group sensor_key max_try tags new_only log_sensor
   sensor_group="default"
   tags=
   max_try=1
   new_only=0
   log_sensor=0
   while (( $# > 0)); do
      case "${1}" in
         "-group"|"-g") shift; sensor_group="${1}"                ;;
         "-try"|"-t") shift; max_try="${1}"                       ;;
         "-new"|"-n") new_only=1                                  ;;
         "-tags"|"-tag") shift; tags="$(utl_format_tags "${1}")"  ;;
         "-log"|"-l") log_sensor=1                                ;;
         *) break                                                 ;;
      esac
      shift
   done
   utl_raise_invalid_option "sensor_check" "(( $# == 1 ))" "$*" && ${returnFalse} 
   sensor_key="${1}"
   if cat | _sensorCheck "${sensor_group}" "${sensor_key}" ${max_try} ${new_only}; then
      (( ${log_sensor} )) && _sensorLogSensor "${sensor_group}" "${sensor_key}" "${tags:-}"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _sensorCheck {
   # Read standard input, check the sensor, return true if triggered.
   # >>> _sensorCheck "sensor_group" "sensor_key" max_try new_only
   ${arcRequireBoundVariables}
   debug3 "_sensorCheck: $*"
   typeset sensor_group sensor_key max_try new_only sensor_dir short_log \
      status_file diffs_file sensor_new_file sensor_file try_count
   sensor_group="${1}"
   sensor_key="${2}"
   max_try="${3}"
   new_only="${4}"
   sensor_dir="${_sensorHome}/${sensor_group}"
   mkdir -p "${sensor_dir}"
   sensor_file="${sensor_dir}/${sensor_key}.x"
   sensor_new_file="${sensor_dir}/${sensor_key}.n" && cp /dev/null "${sensor_new_file}"
   diffs_file="${sensor_dir}/${sensor_key}.d" && cp /dev/null "${diffs_file}"
   status_file="${sensor_dir}/${sensor_key}.s"
   short_log="${sensor_dir}/${sensor_key}.l"
   touch "${sensor_new_file}"
   cat >> "${sensor_new_file}"
   [[ ! -f "${sensor_file}" ]] && cp "${sensor_new_file}" "${sensor_file}"
   if (( ${new_only} )); then
      diff "${sensor_file}" "${sensor_new_file}" | grep "^> " > "${diffs_file}"
   else
      diff "${sensor_file}" "${sensor_new_file}" > "${diffs_file}"
   fi
   try_count=0
   if [[ -s "${diffs_file}" ]]; then
      echo "failing" > "${status_file}"
      counters_set "sensors,failing,+1"
      try_count=$(cache_get -group "sensors_${sensor_group}" -default 0 "${sensor_key}_try_count")
      ((try_count=try_count+1))
   else
      echo "passed" > "${status_file}"
      counters_set "sensors,passed,+1"
   fi
   cache_save -group "sensors_${sensor_group}" "${sensor_key}_try_count" "${try_count}"
   if (( ${try_count} >= ${max_try} )); then
      echo "failed" > "${status_file}"
      date >> "${short_log}"
      cache_save -group "sensors_${sensor_group}" "${sensor_key}_try_count" "0"
      cp "${sensor_new_file}" "${sensor_file}"
      counters_set "sensors,failed,+1"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _sensorLogSensor {
   # Handles a sensor detection event.
   # >>> _sensorLogSensor "sensor_group" "sensor_key" "tags"
   ${arcRequireBoundVariables}
   debug3 "_sensorLogSensor: $*"
   typeset sensor_group sensor_key tags event_key
   sensor_group="${1}"
   sensor_key="${2}"
   tags="${3:-"x"}"
   event_key="sensor_${sensor_group}_${sensor_key}"
   log_notice \
      -logkey "${event_key}" \
      -tags "${tags}" \
      "Sensor '${sensor_key}' change detected in the '${sensor_group}' sensor group."
   sensor_get_last_diff -g "${sensor_group}" "${sensor_key}" | \
      log_info -stdin -logkey "sensors" -tags "${sensor_key}" "'diff' Output"
   sensor_get_last_detected_times -g "${sensor_group}" "${sensor_key}" 10 | \
      log_info -stdin -logkey "sensors" -tags "${sensor_key}" "Last 10 failures recorded for this sensor."
}

function sensor {
   # Sensors detect changes in input.
   # >>> sensor [-group,-g "X='default'"] [-try,-t X] [-new,-n] [-tags "X,x"] [-log,-l] "sensor_key"
   # -group: The sensor group.
   # -try: The number of times to try before triggering a sensor.
   # -new: Only new lines are considered when detecting changes.
   # -tags: List of tags.
   # -log: Log sensor events when triggered.
   # sensor_key: Unique string within a group which identifies a sensor.
   ${arcRequireBoundVariables}
   debug3 "sensor: $*"
   typeset sensor_key max_try new_only sensor_file try_count sensor_group log_sensor
   typeset diffs_file sensor_new_file status_file sensor_dir short_log tags
   max_try=1
   new_only=0
   sensor_group="default"
   tags=
   log_sensor=0
   while (( $# > 0)); do
      case $1 in
         "-group"|"-g") shift; sensor_group="${1}"        ;;
         "-try"|"-t") shift; max_try="${1}"               ;;
         "-new"|"-n") new_only=1                          ;;
         "-tags") shift; tags="$(utl_format_tags "${1}")" ;;
         "-log"|"-l") log_sensor=1                        ;;
         *) break                                         ;;
      esac
      shift
   done
   utl_raise_invalid_option "sensor" "(( $# == 1 ))" "$*" && ${returnFalse} 
   sensor_key="${1}"
   str_raise_not_a_key_str "sensor" "${sensor_key}" && ${returnFalse}  
   if cat | _sensorCheck "${sensor_group}" "${sensor_key}" ${max_try} ${new_only}; then
      (( ${log_sensor} )) && _sensorLogSensor "${sensor_group}" "${sensor_key}" "${tags:-}" 
      sensor_get_last_diff -g "${sensor_group}" "${sensor_key}"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}


function sensor_exists {
   # Return true if the provided sensor exists.
   # >>> sensor_exists [-group "X"] "sensor_key"
   ${arcRequireBoundVariables}
   debug3 "sensor_exists: $*"
   typeset sensor_key sensor_group sensor_dir
   sensor_group="default"
   while (( $# > 0)); do
      case $1 in
         "-group"|"-g") shift; sensor_group="${1}" ;;
         *) break                                  ;;
      esac
      shift
   done
   utl_raise_invalid_option "sensor_exists" "(( $# == 1 ))" "$*" && ${returnFalse} 
   sensor_key="${1}"
   sensor_dir="${_sensorHome}/${sensor_group}"
   if [[ -f "${sensor_dir}/${sensor_key}.n" ]]; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}


function sensor_return_sensor_value {
   # Return the current value/text stored by the sensor.
   # >>> sensor_return_sensor_value [-group,-g "X"] "sensor_key"
   ${arcRequireBoundVariables}
   typeset sensor_key sensor_group sensor_dir
   sensor_group="default"
   while (( $# > 0)); do
      case $1 in
         "-group"|"-g") shift; sensor_group="${1}" ;;
         *) break                                  ;;
      esac
      shift
   done
   utl_raise_invalid_option "sensor_return_sensor_value" "(( $# == 1 ))" "$*" && ${returnFalse} 
   sensor_key="${1}"
   sensor_dir="${_sensorHome}/${sensor_group}"
   cat "${sensor_dir}/${sensor_key}.n" 
   ${returnTrue} 
}


function sensor_get_last_diff {
   # Return the diff from last time sensor ran.
   # >>> sensor_get_last_diff [-group,-g "X"] "sensor_key"
   ${arcRequireBoundVariables}
   typeset sensor_key diffs_file sensor_group
   sensor_group="default"
   while (( $# > 0)); do
      case $1 in
         "-group"|"-g") shift; sensor_group="${1}" ;;
         *) break                                  ;;
      esac
      shift
   done
   utl_raise_invalid_option "sensor_get_last_diff" "(( $# == 1 ))" "$*" && ${returnFalse} 
   sensor_key="${1}"
   is_not_defined "${1}" && ${returnFalse}
   diffs_file="${_sensorHome}/${sensor_group}/${sensor_key}.d"
   file_exists "${diffs_file}" && cat "${diffs_file}"
}

function _sensorListStatuses {
   # Returns the list of possible sensor statuses.
   # >>> _sensorListStatuses
   cat <<EOF
passed
failed
failing
EOF
}

function sensor_get_sensor_status {
   # Returns last status. Can be one of 'passed', 'failing', 'failed'.
   # >>> sensor_get_sensor_status [-group,-g "X"] "sensor_key"
   ${arcRequireBoundVariables}
   debug3 "sensor_get_sensor_status: $*"
   typeset sensor_key sensor_group
   sensor_group="default"
   while (( $# > 0)); do
      case $1 in
         "-group"|"-g") shift; sensor_group="${1}" ;;
         *) break                                  ;;
      esac
      shift
   done
   utl_raise_invalid_option "sensor_get_sensor_status" "(( $# == 1 ))" "$*" && ${returnFalse} 
   sensor_key="${1}"
   status_file="${_sensorHome}/${sensor_group}/${sensor_key}.s"
   cat "${status_file}" | debugd2
   cat "${status_file}" 2> /dev/null
}


function sensor_delete_sensor {
   # Delete a sensor by key.
   # >>> sensor_delete_sensor [-group,-g "X"] "sensor_key"
   ${arcRequireBoundVariables}
   typeset sensor_key sensor_file sensor_group
   sensor_group="default"
   while (( $# > 0)); do
      case $1 in
         "-group"|"-g") shift; sensor_group="${1}" ;;
         *) break                                  ;;
      esac
      shift
   done
   utl_raise_invalid_option "sensor_delete_sensor" "(( $# == 1 ))" "$*" && ${returnFalse} 
   sensor_key="${1}"
   find "${_sensorHome}/${sensor_group}" -type f -name "${sensor_key}.*" -exec rm {} \;
   ${returnTrue} 
}       


function sensor_passed {
   # Return true if "sensor_key" passed.
   # >>> sensor_passed [-group,-g "X"] "sensor_key"
   ${arcRequireBoundVariables}
   debug3 "sensor_passed: $*"
   typeset sensor_key
   sensor_group="default"
   while (( $# > 0)); do
      case $1 in
         "-group"|"-g") shift; sensor_group="${1}" ;;
         *) break                                  ;;
      esac
      shift
   done
   utl_raise_invalid_option "sensor_passed" "(( $# == 1 ))" "$*" && ${returnFalse} 
   sensor_key="${1}"
   if [[ "$(sensor_get_sensor_status -group "${sensor_group}" "${sensor_key}")" == "passed" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}  


function sensor_is_failing {
   # Return true if "sensor_key" is failing.
   # >>> sensor_is_failing [-group,-g "X"] "sensor_key"
   ${arcRequireBoundVariables}
   typeset sensor_key sensor_group
   sensor_group="default"
   while (( $# > 0)); do
      case $1 in
         "-group"|"-g") shift; sensor_group="${1}" ;;
         *) break                                  ;;
      esac
      shift
   done
   utl_raise_invalid_option "sensor_is_failing" "(( $# == 1 ))" "$*" && ${returnFalse} 
   sensor_key="${1}" 
   if [[ $(sensor_get_sensor_status -group "${sensor_group}" "${sensor_key}") == "failing" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}  


function sensor_failed {
   # Return true if "sensor_key" failed.
   # >>> sensor_failed [-group,-g "X"] "sensor_key"
   ${arcRequireBoundVariables}
   typeset sensor_key sensor_group
   sensor_group="default"
   while (( $# > 0)); do
      case $1 in
         "-group"|"-g") shift; sensor_group="${1}" ;;
         *) break                                  ;;
      esac
      shift
   done
   utl_raise_invalid_option "sensor_failed" "(( $# == 1 ))" "$*" && ${returnFalse} 
   sensor_key="${1}" 
   if [[ $(sensor_get_sensor_status -group "${sensor_group}" "${sensor_key}") == "failed" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}  


function sensor_delete_sensor_group {
   # Delete all of the sensors in a group.
   # >>> sensor_delete_sensor_group "sensor group"
   ${arcRequireBoundVariables}
   typeset sensor_group 
   utl_raise_invalid_option "sensor_delete_sensor_group" "(( $# == 1))" "$*" && ${returnFalse} 
   sensor_group="${1}"
   if [[ -d "${_sensorHome}/${sensor_group}" ]]; then
      rm -rf "${_sensorHome}/${sensor_group}"
   fi
   ${returnTrue} 
}


function sensor_get_last_detected_times {
   # Return the last X times the sensor detected a change.
   # >>> sensor_get_last_detected_times [-group,-g "X"] "sensor_key" [X=10]
   # group: Sensor group.
   # sensor_key: Unique key of the sensor.
   # X: Number of records to return.
   ${arcRequireBoundVariables}
   typeset sensor_key sensor_group n sensor_dir
   n=10
   sensor_group="default"
   while (( $# > 0)); do
      case "${1}" in
         "-group"|"-g") shift; sensor_group="${1}" ;;
         *) break                                  ;;
      esac
      shift
   done
   utl_raise_invalid_option "sensor_get_last_detected_times" "(( $# >= 1 ))" "$*" && ${returnFalse} 
   sensor_key="${1}"
   [[ -n "${2:-}" ]] && n="${2}"
   sensor_dir="${_sensorHome}/${sensor_group}"
   if [[ -f "${sensor_dir}/${sensor_key}.l" ]]; then
      tail -${n} "${sensor_dir}/${sensor_key}.l"
   fi
   ${returnTrue} 
}


function sensor_get_fail_count {
   # Return the counter value for the sensor fail count.
   # >>> sensor_get_fail_count [-group,-g "X"] "sensor_key"
   ${arcRequireBoundVariables}
   typeset sensor_key sensor_group sensor_dir
   sensor_group="default"
   while (( $# > 0)); do
      case $1 in
         "-group"|"-g") shift; sensor_group="${1}" ;;
         *) break                                  ;;
      esac
      shift
   done
   utl_raise_invalid_option "sensor_get_fail_count" "(( $# == 1 ))" "$*" && ${returnFalse} 
   sensor_key="${1}"
   sensor_dir="${_sensorHome}/${sensor_group}"
   if [[ -f "${sensor_dir}/${sensor_key}.l" ]]; then
      cat "${sensor_dir}/${sensor_key}.l" | wc -l | str_trim_line -stdin
   else
      echo 0
   fi
   ${returnTrue} 
}

function sensor_list_sensors {
   #
   # >>> sensor_list_sensors [-group,-g "X"]
   ${arcRequireBoundVariables}
   debug3 "sensor_list_sensors: $*"
   typeset sensor_group sensor_dir
   sensor_group="default"
   while (( $# > 0)); do
      case $1 in
         "-group"|"-g") shift; sensor_group="${1}" ;;
         *) break                                  ;;
      esac
      shift
   done
   utl_raise_invalid_option "sensor_list_sensors" "(( $# == 0 ))" "$*" && ${returnFalse} 
   sensor_dir="${_sensorHome}/${sensor_group}"
   find "${sensor_dir}" -type f -name "*.x" | file_get_file_root_name -stdin
}


function _sensorThrowError {
   # Returns error message to standard error.
   # >>> _sensorThrowError "error message"
   throw_error "arcshell_sensor.sh" "${1}"
}


