
# module_name="Statistics Extended"
# module_about="Extends the statistics interface."
# module_version=1
# module_image=""
# copyright_notice="Copyright 2019 Arclogic Software"

function stats_read_counter_group {
   # Reads a counter group as a source for stats.
   # >>> stats_read_counter_group [-s|-m|-h|-v] [-tags,-t "X,x"] "counter_group" 
   ${arcRequireBoundVariables}
   typeset counter_group stat_calc tags 
   debug3 "stats_read_counter_group: $*"
   ${arcRequireBoundVariables}
   stat_calc="value"
   tags=""
   while (( $# > 0)); do
      case "${1}" in 
         # Remove spaces, replace commas with spaces.
         "-t"|"-tags"|"-tag") shift; tags="-t $(utl_format_tags "${1}")" ;;
         "-s"|"-m"|"-h"|"-v") stat_calc="${1}"                           ;;
         *) break                                                        ;;
      esac
      shift
   done 
   utl_raise_invalid_option "stats_read_counter_group" "(( $# == 1))" "$*" && ${returnFalse}
   counter_group="${1}"
   counters_raise_group_does_not_exist "${counter_group}" && ${returnFalse} 
   _statsReturnCounterGroupMetrics "${counter_group}" | stats_read ${stat_calc} ${tags} "${counter_group}"
   ${returnTrue} 
}

function test_stats_read_counter_group {
   _g_counterSafeMode=0
   counters_delete_group "foo"
   counters_set "foo,10" && counters_update
   stats_read_counter_group -v -t "foo, bar" "foo" && pass_test || fail_test 
   counters_set "foo,20" && counters_update
   stats_read_counter_group -v -t "foo, bar" "foo" && pass_test || fail_test 
}

function _statsReturnCounterGroupMetrics {
   # Return counter group data in the format required for stats_read.
   # >>> _statsReturnCounterGroupMetrics
   ${arcRequireBoundVariables}
   typeset counter_group 
   counter_group="${1}"
   counters_get_group "${counter_group}" | sed -e 's/,=/|/' -e 's/,/_/g'
   ${returnTrue} 
}

function stats_return_gchart_data {
   # Return current data for stat group formated for gcharts.
   # >>> stats_return_gchart_data "stat_group"
   ${arcRequireBoundVariables}
   typeset stat_group
   stat_group="${1}"
   tail -2040 "${_statsDir}/${stat_group}/${stat_group}.csv" | \
      awk -F"|" '{print $14","$3","$4","$5","$6","$7","$8","$16","$18}' | \
      gchart_read_data "${stat_group},val,avg"
   gchart_return_html_page 
}

function stats_return_gchart_hourly_data {
   # Return current data for stat group formated for gcharts.
   # >>> stats_return_gchart_hourly_data "stat_group"
   ${arcRequireBoundVariables}
   typeset stat_group
   stat_group="${1}"
   tail -4000 "${_statsDir}/${stat_group}/${stat_group}-hourly.csv" | \
      awk -F"|" '{print $14","$3","$4","$5","$6",0,0,"$16","$18","$40}' | \
      gchart_read_data "${stat_group},val,%avg,score"
   gchart_return_html_page -log_scale
}

