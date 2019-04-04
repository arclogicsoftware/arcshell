
# module_name="Google Charts"
# module_about="A module for generating charts using Google Charts."
# module_version=1
# module_image="diamond.png"
# copyright_notice="Copyright 2019 Arclogic Software"

_gchartDir="${arcTmpDir}/_arcshell_gcharts"
mkdir -p "${_gchartDir}/tmp"

statsHost="$(hostname)"

_g_gchartDataFile="${_gchartDir}/$$.tmp"

function __readmeGCharts {
   cat <<EOF
# Google Charts
**A module for generating charts using Google Charts.**

EOF
}

function gchart_read_data {
   # Reads chart data from standard input. 
   # >>> gchart_read_data "column_list" 
   # column_list: Comma separated list of column names.
   ${arcRequireBoundVariables}
   echo "${1}" > "${_g_gchartDataFile}.column_list"
   cat > "${_g_gchartDataFile}"
}

function gchart_return_html_page {
   # Renders charts from standard input as an html page.
   # >>> gchart_return_html_page [-log_scale]
   ${arcRequireBoundVariables}
   typeset column_list log_scale
   log_scale=0
    while (( $# > 0)); do
      case "${1}" in
         "-log_scale") log_scale=1 ;;
         *) break ;;
      esac
      shift
   done
   if [[ -s "${_g_gchartDataFile}" ]]; then
         column_list="$(cat "${_g_gchartDataFile}.column_list")"
      awk -v column_list="${column_list}" -v log_scale=${log_scale} \
         -f $arcHome/sh/core/gchart_line_chart.awk \
         "${_g_gchartDataFile}"
      rm "${_g_gchartDataFile}" "${_g_gchartDataFile}.column_list" 
   fi
}


function gchart_datetime_string {
   # Returns the current datatime string compatible with Google charting.
   # >>> gchart_datetime_string
   ${arcRequireBoundVariables}
   m=$(dt_month)
   # Javascript uses zero based months.
   ((m=m-1))
   echo "$(dt_year),${m},$(dt_day),$(dt_hour),$(dt_minute),$(dt_second)"
}

