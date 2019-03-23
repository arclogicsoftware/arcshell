

# module_name="Dates & Times"
# module_about="Makes working with dates and times easier."
# module_version=1
# module_image="calendar-5.png"
# copyright_notice="Copyright 2019 Arclogic Software"

function __setupArcShellDatetime {
   :
}

function dt_return_seconds_since_epoch {
   # Return number of elapsed seconds since the given epoch.
   # >>> dt_return_seconds_since_epoch epoch
   ${arcRequireBoundVariables}
   typeset epoch now x
   epoch=${1}
   now=$(dt_epoch)
   ((x=now-epoch))
   echo ${x}
}

function test_dt_return_seconds_since_epoch {
   :
}

function dt_return_minutes_since_epoch {
   # Return number of elapsed minutes since the given epoch.
   # >>> dt_return_minutes_since_epoch epoch
   ${arcRequireBoundVariables}
   typeset epoch now x
   epoch=${1}
   now=$(dt_epoch)
   ((x=(now-epoch)/60))
   echo ${x}
}

function test_dt_return_minutes_since_epoch {
   :
}

function dt_date_stamp {
   # Return date string in YYYYMMDD format using defined separator.
   # dt_date_stamp ["dateSeparator"]
   # dateSeparator: A string, usually a "-", or "_" used to separate the year, month and day fields.
   typeset s 
   s="${1:-""}"
   date +"%Y${s}%m${s}%d"
}

function test_dt_date_stamp {
   :
}

function dt_seconds_remaining_in_minute {
   # Returns the number of seconds until the top of the next minute.
   # >>> dt_seconds_remaining_in_minute
   echo "60 - $(date +"%S")" | bc
}

function test_dt_seconds_remaining_in_minute {
   :
}

function dt_ymd {
   # Return date in format 'YYYYMMDD', often used as part of a file name.
   date +"%Y%m%d"
}

function test_dt_ymd {
   dt_ymd | assert ">0"
}

function dt_ymd_hms {
   # Return date time in 'YYYY-MM-DD_HHMISS' format.
   # >>> dt_ymd_hms
   date +"%Y-%m-%d_%H%M%S"
}

function test_dt_ymd_hms {
   dt_ymd_hms | ${arcAwkProg} -F"-" '{print $1}' | assert ">0"
   dt_ymd_hms | ${arcAwkProg} -F"_" '{print $2}' | assert ">0"
}

function dt_y_m_d_h_m_s {
   # Return date time in 'YYYY_MM_DD_HH_MI_SS' format.
   # >>> dt_y_m_d_h_m_s [delimiter="_"]
   ${arcRequireBoundVariables}
   typeset d
   d="${1:-"_"}"
   date +"%Y${d}%m${d}%d${d}%H${d}%M${d}%S"
}

function test_dt_y_m_d_h_m_s {
   :
}

function dt_y_m_d_h_m {
   # Return date time in 'YYYY_MM_DD_HH_MI' format.
   # >>> dt_y_m_d_h_m [delimiter="_"]
   ${arcRequireBoundVariables}
   typeset d
   d="${1:-"_"}"
   date +"%Y${d}%m${d}%d${d}%H${d}%M"
}

function test_dt_y_m_d_h_m {
   :
}

function dt_y_m_d_h {
   # Return date time in 'YYYY_MM_DD_HH' format.
   # >>> dt_y_m_d_h [delimiter="_"]
   ${arcRequireBoundVariables}
   typeset d
   d="${1:-"_"}"
   date +"%Y${d}%m${d}%d${d}%H"
}

function test_dt_y_m_d_h {
   :
}

function dt_hour {
   # Returns the current hour (0-23) with leading zeros removed.
   # >>> dt_hour
   date +"%H" | num_correct_for_octal_error -stdin
}

function test_dt_hour {
   dt_hour | assert "<24"
}

function dt_minute {
   # Returns the current minute (0-59) with leading zeros removed.
   # >>> dt_minute
   date +"%M" | num_correct_for_octal_error -stdin
}

function test_dt_minute {
   typeset x
   dt_minute | assert "<60"
   x=$(date +"%M" | num_correct_for_octal_error -stdin)
   dt_minute | assert ${x}
}

function dt_second {
   # Returns the current second (0-59) with leading zeros removed.
   # >>> dt_second
   date +"%S" | num_correct_for_octal_error -stdin
}

function dt_year {
   # Returns the current year.
   # >>> dt_year
   date +"%Y"
}

function test_dt_year {
   :
}

function dt_day {
   # Return current day of month (1-31) with leading zeros removed.
   # >>> dt_day
   date +"%d" | num_correct_for_octal_error -stdin
}

function test_dt_day {
   :
}

function dt_month {
   # Return current month (1-12) with leading zeros removed.
   # >>> dt_month
   date +"%m" | num_correct_for_octal_error -stdin
}

function test_dt_month {
   :
}

function dt_is_weekday {
   # Exit true if current day is a week day.
   # dt_is_weekday
   if ! date | egrep -i "sat|sun" 1> /dev/null; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_dt_is_weekday {
   if dt_is_weekend; then
      ! dt_is_weekday && pass_test || fail_test
   else
      dt_is_weekday && pass_test || fail_test
   fi
}

function dt_is_weekend {
   # Exit true if current day is a week end.
   # dt_is_weekend
   if date | egrep -i "sat|sun" 1> /dev/null; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_dt_is_weekend {
   if dt_is_weekday; then
      ! dt_is_weekend && pass_test || fail_test
   else
      dt_is_weekend && pass_test || fail_test
   fi
}

function _dtReturnEpochAwk {
   # Uses awk to return unix epoch time.
   # >>> _dtReturnEpochAwk
   ${arcAwkProg} 'BEGIN{srand();print srand()}'
}

function test__dtReturnEpochAwk {
   _dtReturnEpochAwk | assert ">0"
   num_is_num $(_dtReturnEpochAwk) && pass_test || fail_test
}

function _dtReturnEpochPerl {
   # Uses perl to return unix epoch time.
   # >>> _dtReturnEpochPerl
   if [[ -f "/usr/bin/perl" ]]; then
      /usr/bin/perl -e 'printf "%d\n", time;'
   else
      perl -e 'printf "%d\n", time;'
   fi
}

function test__dtReturnEpochPerl {
   _dtReturnEpochPerl | assert ">0"
   $(num_is_num $(_dtReturnEpochPerl)) && pass_test || fail_test
}

function _dtReturnEpochLinux {
   # Uses date to return unix epoch time.
   # >>> _dt_ymd_epoch
   date +'%s'
}

function test__dtReturnEpochLinux {
   _dtReturnEpochLinux | assert ">0"
   $(num_is_num $(_dtReturnEpochLinux)) && pass_test || fail_test
}

function _dtReturnEpoch {
   # Get unix epoch using first method which succeeds.
   # >>> _dtReturnEpoch
   x=$(_dtReturnEpochLinux 2> /dev/null)
   if (( $? == 0)); then
      echo ${x}
      return
   fi
   x=$(_dtReturnEpochPerl 2> /dev/null)
   if (( $? == 0)); then
      echo ${x}
      return
   fi
   x=$(_dtReturnEpochAwk 2> /dev/null)
   if (( $? == 0)); then
      echo ${x}
      return
   fi
}

function test__dtReturnEpoch {
   _dtReturnEpoch | assert ">0"
}

function dt_epoch {
   # Return unit epoch in minutes or seconds.
   # >>> dt_epoch
   ${arcRequireBoundVariables}
   typeset epochTime
   epochTime=$(_dtReturnEpoch)
   if [[ -n "${epochTime}" ]]; then
      epochFormat=${1:-"seconds"}
      case ${epochFormat} in
         hour|hours)
            # This one rounded up, we don't want that.
            # printf "%.0f" $(echo "${epochTime} / 3600" | bc -l)
            # This one works.
            echo "${epochTime} / 3600" | bc -l | tr -d ' ' | ${arcAwkProg} -F"." '{print $1}'
            ;;
         minute|minutes)
            echo "${epochTime} / 60" | bc -l | tr -d ' ' | ${arcAwkProg} -F"." '{print $1}'
            ;;
         second|seconds)
            echo "${epochTime}"
            ;;
         *) 
            _dtThrowError "Invalid option in dt_epoch."
            ;;
      esac
   else
      _dtThrowError "Failed to get epoch in dt_epoch."
   fi
}

function test_dt_epoch {
   typeset t
   (( $(dt_epoch 'seconds') > 0 )) && pass_test || fail_test
   t=$(mktempf "$0")
   dt_epoch 'seconds' > "${t}"
   sleep 5
   dt_epoch 'seconds' >> "${t}"
   TIME1=$(head -1 "${t}")
   TIME2=$(tail -1 "${t}")
   ((D=${TIME2}-${TIME1}))
   if (( ${D} > 3 )) && (( ${D} < 8 )); then
      pass_test
   else
      fail_test
   fi
   rmtempf "$0"
}

function dt_return_seconds_from_interval_str {
   # Converts the allowable interval styled strings to the equivalent value in seconds.
   #
   # An interval string looks like this, 1d, 1h, 1m, 1s, where d=day, h=hour, m=minutes, s=seconds. This function converts those values to seconds, so 1h returns 3600.
   # >>> dt_return_seconds_from_interval_str "intervalString"
   # **Example**
   # ```
   # numberOfSeconds=$(dt_return_seconds_from_interval_str "1h")
   # echo ${numberOfSeconds}
   # 60
   # ```
   ${arcRequireBoundVariables}
   typeset intervalDesignator integerValue numberOfSeconds
   intervalDesignator=$(str_get_last_char ${1})
   if num_is_num "${intervalDesignator}"; then
      numberOfSeconds=${1}
   else 
      integerValue=$(echo "${1}" | sed 's/.$//')
   fi
   case ${intervalDesignator} in 
      "d") ((numberOfSeconds=integerValue*60*60*24)) ;;
      "h") ((numberOfSeconds=integerValue*60*60)) ;;
      "m") ((numberOfSeconds=integerValue*60)) ;;
      "s") ((numberOfSeconds=integerValue*1)) ;;
   esac
   if num_is_num ${numberOfSeconds}; then
      echo ${numberOfSeconds} 
   else
      _dtThrowError "Return value is not a number: dt_return_seconds_from_interval_str: ${numberOfSeconds}: ${1}"
   fi
}

function test_dt_return_seconds_from_interval_str {
   dt_return_seconds_from_interval_str "60s" | assert 60
   dt_return_seconds_from_interval_str "1m" | assert 60
   dt_return_seconds_from_interval_str "1h" | assert 3600
   dt_return_seconds_from_interval_str "1d" | assert 86400
}

function dt_get_duration_from_elapsed_seconds {
   # Takes the number of seconds and returns a formated time string, for example, "10 days, 04:31:23".
   # dt_get_duration_from_elapsed_seconds X
   # X: Number of seconds.
   ${arcRequireBoundVariables}
   typeset totalSeconds x years days hours minutes seconds
   totalSeconds=${1}
   ((years=totalSeconds/47304000))
   if (( ${years} > 0 )); then
      ((totalSeconds=totalSeconds-(years*47304000)))
   fi
   ((days=totalSeconds/86400))
   if (( ${days} > 0 )); then
      ((totalSeconds=totalSeconds-(days*86400)))
   fi
   ((hours=totalSeconds/3600))
   if (( ${hours} > 0 )); then
      ((totalSeconds=totalSeconds-(hours*3600)))
   fi
   ((minutes=totalSeconds/60))
   if (( ${minutes} > 0 )); then
      ((totalSeconds=totalSeconds-(minutes*60)))
   fi
   seconds=totalSeconds
   # x=
   # if (( ${years} )); then
   #    x="$(printf "${years} years, ")"
   # fi
   # if (( ${days} )); then
   #    x="${x:-}$(printf "${days} days, ")"
   # fi
   # if (( ${hours} )); then
   #    x="${x:-}$(printf "${hours} hours, ")"
   # fi
   # if (( ${minutes} )); then
   #    x="${x:-}$(printf "${minutes} minutes")"
   # fi
   # if [[ -z "${x}" ]]; then
   #    x="$(printf "${totalSeconds} seconds")"
   # fi
   # echo ${x} | sed 's/,$//'
   x=
   if (( ${years} )); then
      x="$(printf "${years} years, ")"
   fi
   x="${x:-}$(printf "${days} days, ")"
   x="${x:-}$(printf "%02d:%02d:%02d," "${hours}" "${minutes}" "${totalSeconds}")"
   echo ${x} | sed 's/,$//'
}

function test_dt_get_duration_from_elapsed_seconds {
   :
}

function _dtThrowError {
   # Error handler for this library.
   # >>> _dtThrowError "errorText"
   throw_error "arcshell_datetime.sh" "${1}"
}

