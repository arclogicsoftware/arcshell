
# module_name="Statistics"
# module_about="Stores statistics. Performs aggregation, analysis, and anomaly detection."
# module_version=1
# module_image="radar.png"
# copyright_notice="Copyright 2019 Arclogic Software"

_statsDir="${arcTmpDir}/_arcshell_stats"
mkdir -p "${_statsDir}/tmp"

statsHost="$(hostname)"

# ToDo: add stats_clear or stats_reset.

function __readmeStats {
cat <<EOF
# arcshell_stats.sh

Statistics storage engine with aggregation and calculation capabilities.

EOF
}

function stats_read {
   # Read metrics from standard input and queue for processing. Required input format is "metric|value".
   # >>> stats_read [-s|-m|-h|-v] [-1] [-donottrack,-x] [-tags,-t "X,x"] "stat_group" 
   # -tags,-t: Tag list.
   # -second,-s: Calculate rate per second.
   # -minute,-m: Calculate rate per minute.
   # -hour,-h: Calculate rate per hour.
   # -delta,-v: Calculate the delta.
   # -1: Return results to standard out.
   # -donottrack,-x: Do not track history.
   typeset stat_group stat_calc tags weekday dayofweek tmpFile standard_out do_not_track
   debug3 "stats_read: $*"
   ${arcRequireBoundVariables}
   standard_out=0
   do_not_track=0
   stat_calc="value"
   tags=""
   weekday=0
   dt_is_weekday && weekday=1
   dayofweek=$(date "+%w")
   tmpFile="$(mktempf)"
   while (( $# > 0)); do
      case "${1}" in 
         # Remove spaces, replace commas with spaces.
         "-t"|"-tag"*) shift; tags="$(utl_format_tags "${1}")" ;;
         "-s"|"-second"*) stat_calc="per/sec" ;;
         "-m"|"-minute"*) stat_calc="per/min" ;;
         "-h"|"-hour"*) stat_calc="per/hr" ;;
         "-v"|"-delta"*) stat_calc="delta" ;;
         "-1") standard_out=1 ;;
         "-x"|"-donottrack") do_not_track=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "stats_read" "(( $# == 1))" "$*" && ${returnFalse}
   stat_group="${1}"
   str_raise_not_a_key_str "stats_read" "${stat_group}" && ${returnFalse}  
   if [[ -n "${tags:-}" ]]; then
      tags="${tags},${stat_group}"
   else
      tags="${stat_group}"
   fi
   _statsHourChanged "${stat_group}" && _statsGenerateHourlyAverageValues "${stat_group}"
   # This is the header record.
   echo ">|$(dt_epoch)|$(dt_y_m_d_h_m_s "|" | sed 's/|0/|/g')|${weekday}|${dayofweek}|${stat_group}|${stat_calc}" | \
      tee -a "${_statsDir}/tmp/${stat_group}.appendedDatasets" > \
      "${_statsDir}/tmp/${stat_group}.lastDataset"
   # debug0 "appendedDatasets-1"
   # cat "${_statsDir}/tmp/${stat_group}.appendedDatasets" | debugd0
   # debug0 "lastDataset"
   # cat "${_statsDir}/tmp/${stat_group}.lastDataset" | debugd0
   # Inject the averages data if it exists.
   if [[ -f "${_statsDir}/${stat_group}/${stat_group}-averages.csv" ]]; then
      cat "${_statsDir}/${stat_group}/${stat_group}-averages.csv" >> \
         "${_statsDir}/tmp/${stat_group}.appendedDatasets"
   fi
   if [[ "${stat_calc}" != "value" ]]; then
      cat | tee -a "${_statsDir}/tmp/${stat_group}.appendedDatasets" >> \
         "${_statsDir}/tmp/${stat_group}.lastDataset"
   else
      cat >> "${_statsDir}/tmp/${stat_group}.appendedDatasets"
   fi
   # debug0 "appendedDatasets-2"
   # cat "${_statsDir}/tmp/${stat_group}.appendedDatasets" | debugd0
   mkdir -p "${_statsDir}/${stat_group}"
   ${arcAwkProg} -v tags="${tags}" -f "${arcHome}/sh/core/_stats_calc.awk" \
      "${_statsDir}/tmp/${stat_group}.appendedDatasets" > "${tmpFile}"
   if (( ${standard_out} )); then
      cat "${tmpFile}" | awk -F"|" '{print $14"|"$16}'
   fi
   if ! (( ${do_not_track} )); then
      cat "${tmpFile}" >> "${_statsDir}/${stat_group}/${stat_group}.csv"
   fi
   rm "${tmpFile}"
   mv "${_statsDir}/tmp/${stat_group}.lastDataset" "${_statsDir}/tmp/${stat_group}.appendedDatasets"
   ${returnTrue} 
}

function _statsHourChanged {
   # Return true if the hour we have been operating in has changed.
   # >>> _statsHourChanged "stat_group"
   ${arcRequireBoundVariables}
   typeset stat_group
   stat_group="${1}"
   if dt_y_m_d_h | sensor_check -group "arcshell_stats" "dt_y_m_d_h_${stat_group}"; then
      ${returnTrue}
   else
      ${returnFalse} 
   fi
}

function _statsReturnEpochSecondsAgo {
   # Returns the value of current epoch minus N seconds.
   # >>> _statsReturnEpochSecondsAgo seconds
   ${arcRequireBoundVariables}
   echo $(dt_epoch) - ${1} | bc -l
}

function _statsGenerateHourlyAverageValues {
   # Takes the raw data and generates hourly averages. Only processes the last 3600 seconds of data.
   # >>> _statsGenerateHourlyAverageValues "stat_group" 
   ${arcRequireBoundVariables}
   debug3 "_statsGenerateHourlyAverageValues: $*"
   typeset stat_group one_hour_ago_epoch d
   stat_group="${1}"
   # Stats using -donottrack option won't have a .csv file.
   ! [[ -f "${_statsDir}/${stat_group}/${stat_group}.csv" ]] && ${returnTrue} 
   one_hour_ago_epoch=$(_statsReturnEpochSecondsAgo 3600)
   #x=$(_statsReturnEpochSecondsAgo 4000000)
   d="$(dt_year)|$(dt_month)|$(dt_day)|$(dt_hour)"
   # Limits the records processed to those that are less than one hour old.
   ${arcAwkProg} -F"|" '$1>'${one_hour_ago_epoch} "${_statsDir}/${stat_group}/${stat_group}.csv" | \
      ${arcAwkProg} -f "${arcHome}/sh/core/_stats_calc_generate_hourly.awk" \
      | grep -v "${d}" >> "${_statsDir}/${stat_group}/${stat_group}-hourly.csv"
   debug3 "_statsGenerateHourlyAverageValues: Complete"
   _statsGenerateAveragesReference "${stat_group}"
}

function _statsGenerateAveragesReference {
   # Generates the references used to determine normality of current values.
   # >>> _statsGenerateAveragesReference "stat_group"
   ${arcRequireBoundVariables}
   debug_set_level 3
   debug3 "_statsGenerateAveragesReference: $*"
   typeset stat_group 
   stat_group="${1}"
      ${arcAwkProg} -f "${arcHome}/sh/core/_stats_calc_generate_averages.awk" \
      "${_statsDir}/${stat_group}/${stat_group}-hourly.csv" \
      > "${_statsDir}/${stat_group}/${stat_group}-averages.csv"
   debug3 "_statsGenerateAveragesReference: Complete"
   debug_set_level 0
}

function stat_groups_list {
   # Return the list of all stat groups.
   # >>> stat_groups_list [-l|-a]
   # -l: Long list. Include file path to the keyword configuration file.
   # -a: All. List every configuration file for every keyword.
   ${arcRequireBoundVariables}
   config_list_all_objects $* "stat_groups"
}

function stat_group_delete {
   # Delete a stats group.
   # >>> stat_group_delete "stat_group"
   ${arcRequireBoundVariables}
   typeset stat_group 
   stat_group="${1}"
   config_delete_object "stat_group" "${stat_group}"
}

