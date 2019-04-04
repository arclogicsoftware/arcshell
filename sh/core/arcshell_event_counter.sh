
# module_name="Event Counter"
# module_about="This module counts things using text based indicators."
# module_version=1
# module_image="view-1.png"
# copyright_notice="Copyright 2019 Arclogic Software"

_eventcounterDir="${arcTmpDir}/_arcshell_event_counters"
mkdir -p "${_eventcounterDir}"

function __readmeFile {
   cat <<EOF
> Question: How does a large software project get to be one year late? Answer: One day at a time! -- Fred Brooks

# Event Counter

**This module counts things using text based indicators.**
EOF
}

function event_counter_add_event {
   # Records an event in file using the defined prefix and character.
   # >>> event_counter_add_event [-prefix,-p "X"] [group] ["character"]
   # -prefix: Events are recorded on a the line defined using the prefix. The default value includes user host, date, and time in hourly format.
   # group: Events are recorded in a unique file for each group.
   # character: Events are recorded using the specified character.
   ${arcRequireBoundVariables}
   typeset group char prefix
   group=
   prefix="$(_eventCounterReturnDefaultPrefix)"
   while (( $# > 0)); do
      case "${1}" in
         "-prefix"|"-p") shift; prefix="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "event_counter_add_event" "(( $# <= 2 ))" "$*" && ${returnFalse}
   group="${1:-}"
   str_raise_not_a_key_str "event_counter_add_event" "${group:-}" && ${returnFalse} 
   char="${2:-"."}"
   if ! [[ -f "${_eventcounterDir}/${group}.txt" ]]; then
      printf "%s " "${prefix}" >> "${_eventcounterDir}/${group}.txt"
   elif ! grep "${prefix} " "${_eventcounterDir}/${group}.txt" 1> /dev/null; then
      printf "\n%s" "${prefix} " >> "${_eventcounterDir}/${group}.txt"
   fi
   printf "%s" "${char}" >> "${_eventcounterDir}/${group}.txt"
}

function _eventCounterReturnDefaultPrefix {
   # Returns the default event counter prefix.
   # >>> _eventCounterReturnDefaultPrefix
   echo "${arcNode} $(dt_month)/$(dt_day) $(dt_hour):00"
}

