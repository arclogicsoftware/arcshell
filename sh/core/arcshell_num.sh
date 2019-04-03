
# module_name="Numbers"
# module_about="Number and math functions."
# module_version=1
# module_image="division.png"
# copyright_notice="Copyright 2019 Arclogic Software"

function __readmeNum {
   cat <<EOF
# Numbers
**Number and math functions.**

There are a "number" of number and math related functions in this library. In most cases the name of the function should make the purpose clear.
EOF
}

function num_line_count {
   # Returns line count. Removes any left padded blanks that may show up in Solaris with wc use.
   # >>> num_line_count [-stdin] ["file_name"]
   ${arcRequireBoundVariables}
   if [[ "${1:-}" == "-stdin" ]]; then
      cat | wc -l | tr -d ' '
   elif (( $# == 1 )); then
      wc -l "${1}" | cut -d " " -f1 | tr -d ' '
   else
      cat | wc -l | tr -d ' '
   fi
}

function test_num_line_count {
   #
   :
}

function num_random {
   # Return a random number between two values.
   # >>> num_random [minValue=0] maxValue
   ${arcRequireBoundVariables}
   typeset minValue maxValue
   if (( $# == 2 )); then
      minValue=${1}
      maxValue=${2}
   else
      minValue=0
      maxValue=${1:-0}
   fi
   if (( ${minValue} < 0 || ${maxValue} < 0 )); then
      log_error -2 -logkey "numbers" "Negative numbers not allowed: $*: num_random"
      ${returnFalse} 
   fi
   ${arcAwkProg} -v min=${minValue} -v max=${maxValue} 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'
   ${returnTrue} 
}

function num_round_to_multiple_of {
   # Round a whole number to the nearest multiple of another number.
   # >>> num_round_to_multiple_of "numberToRound" "roundToNearest"
   # numberToRound: The number that needs to be rounded.
   # roundToNearest: Round the number above to the nearest multiple of this number.
   ${arcRequireBoundVariables}
   typeset numberToRound roundToNearest decimalToHundrethsPosition x integerValue
   numberToRound=${1}
   roundToNearest=${2}
   x=$(echo ${numberToRound} / ${roundToNearest} | bc -l)
   integerValue=$(echo ${numberToRound} / ${roundToNearest} | bc -l | cut -d"." -f1)
   [[ -z "${integerValue}" ]] && integerValue=0
   #debug2 "integerValue=${integerValue}, x=${x}, numberToRound=${numberToRound}, roundToNearest=${roundToNearest}"
   decimalToHundrethsPosition=$(echo "${x}" | cut -d"." -f2) 
   #debug2 "decimalToHundrethsPosition=${decimalToHundrethsPosition}"
   decimalToHundrethsPosition=${decimalToHundrethsPosition:0:2}
   #debug2 "decimalToHundrethsPosition=${decimalToHundrethsPosition}"
   decimalToHundrethsPosition=$(num_correct_for_octal_error ${decimalToHundrethsPosition})
   #debug2 "decimalToHundrethsPosition=${decimalToHundrethsPosition}"
   if (( ${decimalToHundrethsPosition} >= 50 )); then
      ((x=(integerValue*roundToNearest)+roundToNearest))
   else
      ((x=(integerValue*roundToNearest)+0))
   fi
   echo ${x}
}

function num_floor {
   # Return the whole number floor of a number. 
   # >>> num_floor [-stdin] X
   # X: A number, can be a decimal.
   ${arcRequireBoundVariables}
   typeset x r
   if [[ "${1:-}" == "-stdin" ]]; then
      while read -r x; do
         r=$(echo "${x}" | bc | sed 's/[.].*//')
         [[ -z "${r}" || "${r}" == "-" ]] && r=0
         echo ${r}
      done
   else
      echo "${1:-}" | num_floor -stdin
   fi
}

function num_is_whole {
   # Return true if a number is a whole number.
   # >>> num_is_whole X
   ${arcRequireBoundVariables}
   typeset x
   if num_is_num "${1}"; then
      if (( $(str_instr "." "${1}") == 0 )); then
         ${returnTrue}
      else
         ${returnFalse}
      fi
   else
      log_error -2 -logkey "numbers" "num_is_whole: '${1}' is not a number."
   fi
}

function num_is_even {
   # Return true if number is whole number and is even.
   #
   # >>> num_is_even X
   # X: Any whole number.
   #
   # **Example**
   # ```
   # num_is_even 4 && echo "True" || echo "False"
   # True
   # ```
   ${arcRequireBoundVariables}
   typeset x
   if $(num_is_whole ${1}); then
      ((x=${1} % 2))
      if (( ${x} == 0 )); then
         ${returnTrue}
      else
         ${returnFalse}
      fi
   else
      ${returnFalse}
   fi
}

function num_is_odd {
   # Return true if number is whole number and is odd.
   #
   # >>> num_is_odd X
   # X: Any whole number.
   #
   # **Example**
   # ```
   # $(num_is_odd 4) && echo "True" || echo "False" 
   # False
   # ```
   ${arcRequireBoundVariables}
   typeset x
   if $(num_is_whole ${1}); then
      ((x=${1} % 2))
      if (( ${x} == 1 )); then
         #debug3 "num_is_odd: ${x}: True"
         ${returnTrue}
      else
         #debug3 "num_is_odd: ${x}: False"
         ${returnFalse}
      fi
   else
      ${returnFalse}
   fi
}

function num_is_gt {
   # Return true if first value is greater than the second. Decimals are allowed.
   # >>> num_is_gt isThisNum gtThanThisNum
   # isThisNum: Integer or decimal.
   # gtThanThisNum: Integer or decimal.
   ${arcRequireBoundVariables}
   #debug3 "num_is_gt: $*"
   typeset isThisNum gtThanThisNum
   isThisNum="${1}"
   gtThanThisNum="${2}"
   # Solaris bug prevents us from using bc here. This is a good description of 
   # the issue. https://globalroot.wordpress.com/2016/09/07/solaris-quirk-bc-bad-calculator/
   if (( $(eval "${arcAwkProg} 'BEGIN {print ("$isThisNum" > "$gtThanThisNum")}'") )); then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function num_range {
   # Return a range of whole numbers from beginning value to ending value.
   # >>> num_range start end
   # start: Whole number to start with.
   # end: Whole number to end with.
   ${arcRequireBoundVariables}
   typeset s e v
   s=${1}
   e=${2}
   if (( ${e} >= ${s} )); then
      v=${s}
      while (( ${v} <= ${e} )); do
         echo ${v}
         ((v=v+1))
      done
   elif (( ${e} < ${s} )); then
      v=${s}
      while (( ${v} >= ${e} )); do
         echo ${v}
         ((v=v-1))
      done
   fi
}

function num_max {
   # Get max from a series of numbers. Numbers are supplied as argments or standard input. Decimals are allowable.
   # >>> num_max [X...]
   # X: One or more numbers separated by spaces.
   ${arcRequireBoundVariables}
   (
   if (( $# > 0 )); then
      while (( $# > 0 )); do
         echo ${1}
         shift
      done
   else
      cat
   fi
   ) | sort -nrk1,1 | head -1 | utl_remove_blank_lines -stdin
}

function num_min {
   # Get min from a series of numbers. Numbers are supplied as argments or standard input. Decimals are allowable.
   # >>> num_min [X...]
   # X: One or more numbers separated by spaces.
   ${arcRequireBoundVariables}
   typeset x
   (
   if (( $# > 0 )); then
      while (( $# > 0 )); do
         echo ${1}
         shift
      done
   else
      while read x; do
         echo ${x}
      done
   fi
   ) | sort -nk1,1 | head -1 | utl_remove_blank_lines -stdin
}

function num_sum {
   # Sum a series of integer or decimal numbers.
   # >>> num_sum [-stdin] [-decimals,-d X] [X...]
   # decimals: Specify the # of decimals. Defaults to zero.
   # -stdin: Read from standard input.
   # X: One or more numbers separated by spaces.
   ${arcRequireBoundVariables}
   typeset d stdin 
   stdin=0
   d=0
   while (( $# > 0)); do
      case "${1}" in
         "-stdin") stdin=1 ;;
         "-decimals"|"-d") shift; d="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "num_sum" "(( $# >= 0 ))" "$*" && ${returnFalse} 
   (
   if (( ${stdin} )); then
      cat 
   else
      echo "$*" | str_split_line " "
   fi
   ) | ${arcAwkProg} '{sum+=$1}; END {printf "%.'${d}'f\n" ,sum}'
}

function num_avg {
   # Avg a series of numbers. Numbers are supplied as argments or standard input. Decimals are allowable.
   # >>> num_avg [X...]
   # X: One or more numbers separated by spaces.
   ${arcRequireBoundVariables}
   (
   if [[ "${1:-}" == "-" ]]; then
      cat 
   else
      echo "$*" | str_split_line " "
   fi
   ) | ${arcAwkProg} '{ sum += $1; n++ } END { if (n > 0) print sum / n; }'
}

function num_stddev {
   # Get standard deviation from a series of numbers. Numbers are supplied as argments or standard input. Decimals are allowable.
   # >>> num_stddev [X...]
   # X: One or more numbers separated by spaces.
   ${arcRequireBoundVariables}
   typeset x
   (
   if (( $# > 0 )); then
      while (( $# > 0 )); do
         echo ${1}
         shift
      done
   else
      while read x; do
         echo ${x}
      done
   fi
   ) | ${arcAwkProg} '{x[NR]=$0; s+=$0} END{a=s/NR; for (i in x){ss += (x[i]-a)^2} sd = sqrt(ss/NR); print sd}'
}

function num_is_num {
   # Return true if input value is a number. Decimals are allowable.
   # >>> num_is_num X
   # X: The variable or string being tested.
   ${arcRequireBoundVariables}
   typeset x 
   x=${1:-}
   if (( $(echo ${1:-'x'} | egrep "^-?[0-9|.]+([.][0-9]+)?$" | egrep -v "\..*\." | wc -l) > 0 )); then
      ${returnTrue}
   else
      debug3 "num_is_num: '${1:-}' is not a number."
      ${returnFalse}
   fi
}

function num_raise_is_not_a_number {
   # Throw error and return true if provided value is not a number.
   # >>> num_raise_is_not_a_number "source" X
   # source: Source of error.
   # X: Expected number.
   ${arcRequireBoundVariables}
   typeset source x
   source="${1}"
   x="${2}"
   if ! num_is_num "${x}"; then
      log_error -2 -logkey "numbers" "Not a number: $*: ${source}"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function num_correct_for_octal_error {
   # Changes numbers like 08.1 to 8.1, because bash will interpret the former as an octal.
   # 
   # Google "bash value too great for base" to understand more. At the time of this 
   # writing it is just used to strip leading zeros from some variables in the cron.sh
   # library. 
   #
   # This function also reads from standard input.
   # 
   # >>> num_correct_for_octal_error [-stdin | X ]
   # X: Integer or decimal value with potential leading zeros.
   ${arcRequireBoundVariables}
   typeset x r
   utl_raise_invalid_option "num_correct_for_octal_error" "(( $# == 1))" && ${returnFalse} 
   if [[ "${1:-}" == "-stdin" ]]; then
      while read x; do
         r=$(echo "${x}" | sed -e 's/^0*//' -e 's/^\./0./' -e 's/\.$//')
         [[ -z "${r}" ]] && r=0
         echo ${r}
      done
   else 
      echo "${1:-}" | num_correct_for_octal_error -stdin     
   fi
}

function num_is_gt_zero {
   # Return true if the number is greater than zero. Works with decimals.
   # >>> num_is_gt_zero X
   # X: A number.
   ${arcRequireBoundVariables}
   if $(num_is_gt ${1} 0); then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function num_is_zero {
   # Ext true if the number is zero. Works with decimals.
   # >>> num_is_zero X
   # X: A number.
   ${arcRequireBoundVariables}
   if (( $(eval "${arcAwkProg} 'BEGIN {print ("$1" == "0")}'") )); then
   #if (( $(echo "${1:-1} == 0" | bc -l) )); then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

