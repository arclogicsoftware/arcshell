
# module_name="Cron"
# module_about="Make and schedule solutions using cron styled attributes."
# module_version=1
# module_image="clock.png"
# copyright_notice="Copyright 2019 Arclogic Software"

function __readmeCron {
cat <<EOF
> I do not care if it works on your system, I am not gonna ship your computer. -- Anonymous

# Cron

**Make and schedule solutions using cron styled attributes.**

See the Unix documentation for basic information on cron expressions. 

ArcShell supports the following features.

* Like typical cron entries, asterisks are wild cards.
* Ranges are allowed. For example, “0,15,30,45 8-17 * * *”, runs jobs at 4 times per hour between 8:00 AM and 5:59 PM.
* Reverse ranges are also allowed. For example, “/15 18-6 * * *”, also runs jobs 4 times per hour but between 6:00 PM and 6:59 AM. Not the example also uses a divisor, which is also allowable.
* Each field can contain more than one entry. For example, “0 2-4,6-8 * * *”, runs jobs at 2:00, 3:00, 4:00, 6:00, 7:00 and 8:00 AM. Just make sure there are no spaces within the individual fields.
* Months can be represented using digits (1-12) or 3-character abbreviations. For example, “0 12 * APR-SEP *” runs jobs at 12:00 AM every day between April and September.
* Day of week can be represented using digits (0-6 where 0 is Sunday) or three-character abbreviations. For example, “0 2 * * SUN-WED”, runs jobs at 2:00 AM Sunday through Wednesday.

EOF
}   

function __exampleCron {
   if cron_is_true "* 8-16 * * *"; then
      echo "Hour is between 8AM and 4PM."
   fi
}
         
function cron_is_true {
   # Return true if the provided cron expression is true.
   # >>> cron_is_true "cronExpression"
   ${arcRequireBoundVariables}
   typeset cronExpression nMinutes nHour nDate nMonth nDay fieldNum
   typeset cMinutes cHour cDate cMonth cDay
   cronExpression="$(echo "${1}" | sed 's/\*/X/g')"
   # debug3 "cron_is_true: $*"
   if ! _cronIsValidCronExpression "${cronExpression}"; then
      ${returnFalse}
   fi
   IFS=' ' read cMinutes cHour cDate cMonth cDay <<< "${cronExpression}"

   [[ -z "${cMinutes}" ]] && _throwCronError "Minutes value missing."
   [[ -z "${cHour}" ]] && _throwCronError "Hour value missing."
   [[ -z "${cDate}" ]] && _throwCronError "Day of month value missing."
   [[ -z "${cMonth}" ]] && _throwCronError "Month value missing."
   [[ -z "${cDay}" ]] && _throwCronError "Day of week value missing."

   nMinutes=$(date +'%M' | num_correct_for_octal_error -stdin)
   nHour=$(date +'%H' | num_correct_for_octal_error -stdin)
   nDate=$(date +'%d' | num_correct_for_octal_error -stdin)
   nMonth=$(date +'%m' | num_correct_for_octal_error -stdin)
   nDay=$(date +'%w' | num_correct_for_octal_error -stdin)

   while read fieldNum; do
      case ${fieldNum} in 
         1) nowTime=${nMinutes}; cronTime="${cMinutes}" ;;
         2) nowTime=${nHour}; cronTime="${cHour}" ;;
         3) nowTime=${nDate}; cronTime="${cDate}" ;;
         4) nowTime=${nMonth}; cronTime=$(_cronReturnMonthOfYearInt "${cMonth}") ;;
         5) nowTime=${nDay}; cronTime=$(_cronReturnDayOfWeekInt "${cDay}") ;;
      esac
      if ! _cronIsCronFieldTrue "${cronTime}" ${nowTime}; then
         # debug3 "Not True: fieldNum=${fieldNum}, cronTime=${cronTime}, nowTime=${nowTime}"
         ${returnFalse}
      fi
      # debug3 "True: cronTime=${cronTime} nowTime=${nowTime}"
   done < <(num_range 1 5)
   # debug3 "True: $*: cron_is_true"
   ${returnTrue}
}

function test_cron_is_true {
   cron_is_true "* * * * *" && pass_test || fail_test 
   ! cron_is_true "60 * * *" 2>/dev/null && pass_test || fail_test "Strings with 4 fields should be invalid."
   ! cron_is_true "23" 2>/dev/null && pass_test || fail_test "Strings with 1 field should be invalid."
   ! cron_is_true "* * * *" 2>/dev/null && pass_test || fail_test "Strings with 4 fields should be invalid."
   cron_is_true "0-59 * * * *" && pass_test || fail_test
   cron_is_true "* 0-23 * * *" && pass_test || fail_test
   cron_is_true "* * 1-31 * *" && pass_test || fail_test
   cron_is_true "* * * 1-12 *" && pass_test || fail_test
   cron_is_true "* * * * 0-6" && pass_test || fail_test
   cron_is_true "/1 * * * *" && pass_test || fail_test
   cron_is_true "* /1 * * *" && pass_test || fail_test
   cron_is_true "* * /1 * *" && pass_test || fail_test
   cron_is_true "* * * /1 *" && pass_test || fail_test
   cron_is_true "* * * * /1" && pass_test || fail_test
   #debug_start 3
   #unittest_debug_get_for_passing_tests_on
   cron_is_true "* * * 1,2,3,4,5,6,7,8,9,10,11,12 *" && pass_test || fail_test
   #unittest_debug_get_for_passing_tests_off
   cron_is_true "* * * * 0,1,2,3,4,5,6" && pass_test || fail_test
   cron_is_true "/1 0-20,21-59 * * MON-SUN" && pass_test || fail_test
   x=$(echo $(date +'%d') + 1 | bc -l)
   #unittest_debug_get_for_passing_tests_on
   ! cron_is_true "* * ${x} * *" && pass_test || fail_test
   #unittest_debug_get_for_passing_tests_off
}

function _cronIsValidCronExpression {
   # Return true if the cron expression has 5 fields.
   # >>> _cronIsValidCronExpression "cronExpression"
   ${arcRequireBoundVariables}
   typeset cronExpression
   cronExpression="${1}"
   if (( $(echo "${cronExpression}" | str_split_line -stdin " " | wc -l) != 5 )); then
      _throwCronError "A valid cron string should contain 5 fields.: '${cronExpression}'"
      ${returnFalse}
   fi
   ${returnTrue}
}

function _cronIsCronFieldTrue {
   # Parses a single field of the cron expression and exits true if it evaluates to true.
   # >>> _cronIsCronFieldTrue "cronField" "timeInteger"
   ${arcRequireBoundVariables}
   typeset cronField timeInteger cronPartOfField
   cronField="${1}"
   timeInteger=${2}
   [[ "${cronField}" == "X" ]] && ${returnTrue}  
   while IFS=, read cronPartOfField; do
      if _cronIsPartOfFieldTrue "${cronPartOfField}" ${timeInteger}; then
         # debug3 "True: _cronIsCronFieldTrue"
         ${returnTrue}
      fi
   done <<< "${cronField}"
   # debug3 "False: _cronIsCronFieldTrue"
   ${returnFalse}
}

function _cronIsPartOfFieldTrue {
   # Return true if part of a cron field is true.
   # >>> _cronIsPartOfFieldTrue "cronFieldPart" "timeInteger"
   ${arcRequireBoundVariables}
   typeset cronFieldPart timeInteger
   cronFieldPart="${1}"
   timeInteger=${2}
   # debug3 "_cronIsPartOfFieldTrue: $*"
   if [[ "${cronFieldPart}" == "X" ]]; then
      # debug3 "_cronIsPartOfFieldTrue: True"
      ${returnTrue}
   elif (( $(echo "${cronFieldPart}" | grep "\/" | wc -l) )); then
      if _cronIsIntMultiple "${cronFieldPart}" "${timeInteger}"; then
         # debug3 "_cronIsPartOfFieldTrue: True"
         ${returnTrue}
      fi
   elif (( $(echo "${cronFieldPart}" | grep "-" | wc -l) )); then
      if _cronIsIntWithinRange "${cronFieldPart}" "${timeInteger}"; then
         # debug3 "_cronIsPartOfFieldTrue: True"
         ${returnTrue}
      fi
   elif (( $(echo "${cronFieldPart}" | grep "," | wc -l) )); then
      if _cronIsIntWithinList "${cronFieldPart}" "${timeInteger}"; then 
         # debug3 "_cronIsPartOfFieldTrue: True"
         ${returnTrue}
      fi
   elif num_is_num "${cronFieldPart}"; then
      if (( ${cronFieldPart} == ${timeInteger} )); then 
         # debug3 "_cronIsPartOfFieldTrue: True"
         ${returnTrue}
      fi
   else
      _throwCronError "_cronIsPartOfFieldTrue: Unable to parse.: $*"
   fi
   # debug3 "_cronIsPartOfFieldTrue: False"
   ${returnFalse}
}

function _cronIsIntWithinRange {
   # Return true if time integer is within range of the cron field.
   # >>> _cronIsIntWithinRange "cronFieldPart" "timeInteger"
   ${arcRequireBoundVariables}
   typeset leftX rightX integerX
   # debug3 "_cronIsIntWithinRange: $*"
   leftX=$(echo ${1}  | awk -F"-" '{ print $1 }')
   rightX=$(echo ${1} | awk -F"-" '{ print $2 }')
   integerX="${2}"
   if (( ${leftX} < ${rightX} )); then
      (( ${integerX} >= ${leftX} && ${integerX} <= ${rightX} )) && ${returnTrue}
   elif (( ${leftX} > ${rightX} )); then
      (( ${integerX} >= ${leftX} || ${integerX} <= ${rightX} )) && ${returnTrue}
   fi
   # debug3 "_cronIsIntWithinRange: False"
   ${returnFalse}
}

function _cronIsIntWithinList {
   # Return true if time integer is in comma separated list of integers.
   # >>> _cronIsIntWithinList "integerList" "integerX"
   # integerList:
   # integerX:
   ${arcRequireBoundVariables}
   typeset integerX integerList x
   # debug3 "_cronIsIntWithinList: $*"
   integerList="${1}"
   integerX=${2}
   while read x; do
      if (( ${x} == ${integerX} )); then
         ${returnTrue}
      fi
   done < <(echo "${integerList}" | str_split_line -stdin ",")
   # debug3 "_cronIsIntWithinList: False"
   ${returnFalse}
}

function _cronIsIntMultiple {
   # Return true if time integer is multiple of integer.
   # >>> _cronIsIntMultiple "cronFieldPart" "timeInteger"
   ${arcRequireBoundVariables}
   typeset divisorX integerX
   # debug3 "_cronIsIntMultiple: $*"
   divisorX=$(echo "${1}" | _cronRemovesForwardSlashes)
   integerX=${2}
   if (( $(expr ${integerX} % ${divisorX}) == 0 )); then
      ${returnTrue}
   fi
   # debug3 "_cronIsIntMultiple: False"
   ${returnFalse}
}

function _cronReturnDayOfWeekInt {
   # Converts abbreviated days (SUN-SAT) to integers (0-6).
   # _cronReturnDayOfWeekInt "DDD"
   # DDD: Abbreviated day of week, SUN-SAT.
   ${arcRequireBoundVariables}
   typeset x
   x="${1}" 
   echo "${x}" | str_to_upper_case -stdin | sed -e 's/SUN/0/' -e 's/MON/1/' -e 's/TUE/2/' -e 's/WED/3/' -e 's/THU/4/' -e 's/FRI/5/' -e 's/SAT/6/'
}

function _cronReturnMonthOfYearInt {
   # Converts month in MON format JAN-DEC to an integer value.
   # _cronReturnMonthOfYearInt "MON"
   ${arcRequireBoundVariables}
   typeset x
   x="${1}" 
   echo "${x}" | str_to_upper_case -stdin | sed -e 's/JAN/1/' -e 's/FEB/2/' -e 's/MAR/3/' -e 's/APR/4/' -e 's/MAY/5/' -e 's/JUN/6/' -e 's/JUL/7/' -e 's/AUG/8/' -e 's/SEP/9/' -e 's/OCT/10/' -e 's/NOV/11/' -e 's/DEC/12/'
}

function _cronRemovesForwardSlashes {
   # Removes forward slashes from standard input and returns to standard out.
   # _cronRemovesForwardSlashes
   ${arcRequireBoundVariables}
   typeset x
   while IFS= read x; do
      echo "${x}" | sed 's/\///g'
   done
}

function _throwCronError {
   throw_error "arcshell_cron.sh" "${1}"
}  

