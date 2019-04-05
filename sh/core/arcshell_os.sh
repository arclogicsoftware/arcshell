
# module_name="OS"
# module_about="Basic operating system related functions for Unix/Linux."
# module_version=1
# module_image="server.png"
# copyright_notice="Copyright 2019 Arclogic Software"

# ToDo: Add options to summarize by "comm" or "user" or both.

function __readmeOS {
   cat <<EOF
> A code is like love, it has created with clear intentions at the beginning, but it can get complicated. -- Gerry Geek

# OS

**Basic operating system related functions for Unix/Linux.**

EOF
}

function os_return_process_cpu_seconds {
   # Returns a record for each process and converts '0-00:00:00' cpu time to seconds.
   # >>> os_return_process_cpu_seconds
   ${arcRequireBoundVariables}
   ps -eo pid,time,user,comm | tr '/' '_' | awk -f "${arcHome}/sh/core/_os_return_process_cpu_seconds.awk"
}

function os_spawn_busy_process {
   # Spawns busy process N seconds and returns the internal loop count. Breaks if loop count exceeds 10,000.
   # >>> os_spawn_busy_process "seconds"
   # seconds: The number of seconds to run for.
   ${arcRequireBoundVariables}
   typeset duration start_time now_time x
   duration="${1}"
   start_time="$(dt_epoch)"
   now_time=${start_time}
   ((end_time=start_time+duration))
   x=0 
   while (( ${end_time} >= ${now_time} )); do
      ((x=x+1))
      now_time=$(dt_epoch)
      (( ${x} > 10000 )) && break
   done
   echo ${x}
}

# ToDo: Might implement /proc/stat sampling (https://stackoverflow.com/questions/1332861/how-can-i-determine-the-current-cpu-utilization-from-the-shell).

function os_return_cpu_pct_used {
   # Returns current CPU usage.
   # >>> os_return_cpu_pct_used
   ${arcRequireBoundVariables}
   typeset idle_cpu cpu_usage 
   idle_cpu=0
   cpu_usage=0
   case "${arcOSType}" in 
      "LINUX"|"AIX"|"SUNOS") 
         :
         ;;
      *) 
         log_error -logkey "arcshell" -tags "os" "'os_return_cpu_pct_used' is may not operate correctly for this OS." 
         ;;         
   esac
   column_number="$(vmstat 1 1 | str_return_matching_column_num -stdin "id")"
   idle_cpu=$(vmstat 10 2 | tail -1 | awk -v x=${column_number} '{print $x}')
   ((cpu_usage=100-idle_cpu))
   echo ${cpu_usage}
}

function os_return_total_cpu_seconds {
   # Attempts to total up the number of CPU seconds elapsed across all running processes.
   # >>> os_return_total_cpu_seconds
   ${arcRequireBoundVariables}
   typeset v t
   (
   while read v; do
      days=0
      if (( $(str_get_char_count "-" "${v}") == 1 )); then
         days="$(echo "${v}" | cut -d"-" -f1)"
      fi
      t="$(echo "${v}" | cut -d"-" -f2)"
      if (( $(str_get_char_count ":" "${t}") == 1 )); then
         t="0:${t}"
      fi
      IFS=":" read hours minutes seconds < <(echo "${t}")
      ((days=days*24*60*60))
      ((hours=hours*60*60))
      ((minutes=minutes*60))
      ((total=days+hours+minutes+seconds))
      echo ${total}
   done < <(ps -eo time | grep -v "00:00:00" | grep ".*:.*:" | sed -e 's/:0/:/g' -e 's/^0//' | sort -n)
   ) | num_sum -stdin
}

function os_return_vmstat {
   # Returns results from vmstat in a "metric|value".
   # >>> os_return_vmstat [X=10]
   # X: Number of seconds to sample vmstat for at 2 intervals.
   ${arcRequireBoundVariables}
   debug3 "os_return_vmstat: $*"
   typeset tmpFile option x i
   x=10
   num_is_num "${1:-}" && x=${1}
   option=
   tmpFile=$(mktempf)
   case "${arcOSType}" in 
      "SUNOS") option="-S" ;;
      "LINUX") option="-a" ;;
      *) 
   esac
   vmstat ${option} | tail -2 | head -1 | str_split_line -stdin " " | \
     utl_remove_blank_lines -stdin  | \
      grep -n ".*" | tr ":" "_"  > "${tmpFile}_1"
   vmstat ${option} ${x} 2 | tail -1 | sed 's/\-0/0/g' | \
      str_split_line -stdin " " | utl_remove_blank_lines -stdin > "${tmpFile}_2"
   paste -d"|" "${tmpFile}_1" "${tmpFile}_2"
   rm "${tmpFile}"*
   ${returnTrue} 
}

function os_return_load {
   # Return the OS load using the uptime command as a whole number or decimal.
   # >>> os_return_load [-w]
   # -w: Return a whole number.
   if [[ "${1:-}" == "-w" ]]; then
      num_round_to_multiple_of $(uptime | ${arcAwkProg} -F" " '{print $(NF-2)}' | sed 's/,//') 1
   else
      uptime | ${arcAwkProg} -F" " '{print $(NF-2)}' | sed 's/,//'
   fi
}

function os_return_os_type {
   # Return short hostname in upper-case.
   # >>> os_return_os_type
   ${arcRequireBoundVariables}
   uname -s | str_to_upper_case -stdin
}

function os_disks {
   # Return the list of disks available.
   # >>> os_disks
   ${arcRequireBoundVariables}
   case "$(os_return_os_type)" in 
      "LINUX")
         df -k |egrep -v "^\/|:|Available" | sed 's/^/-/g' | ${arcAwkProg} '{print $6}'
         ;;
      "AIX")
         df -k | grep -v "\/proc" | ${arcAwkProg} '{ print $7}' | grep -v "^Mounted"
         ;;
      "SUNOS")
         df -kl 2> /dev/null | ${arcAwkProg} '{print $6}' | egrep -v "^Mounted|SUNWnative"
         ;;
      "HP-UX")
         bdf -l| ${arcAwkProg} '{print $6}' | grep -v "^Mounted"
         ;;
   esac
}
 
function os_is_process_id_process_name_running {
   # Return true if a process ID is running. Checks using process ID alone, or by ID and regular expression.
   # >>> os_is_process_id_process_name_running "processId" ["regex"]
   # processId: Unix process ID we are looking for.
   # regex: Regular expression used to match the line returned by 'ps -ef'.
   ${arcRequireBoundVariables}
   typeset processId regex
   processId="${1}"
   if (( ${processId} == 0 )); then
      ${returnFalse}
   fi
   regex="${2:-}"
   [[ -z "${regex}" ]] && regex=".*"
   if (( $(ps -ef | grep "${processId}" | grep "${regex}" | grep -v "grep" | wc -l | tr -d ' ') > 0 )); then
      debug3 "os_is_process_id_process_name_running: True: $*"
      ${returnTrue}
   else
      debug3 "os_is_process_id_process_name_running: False: $*"
      ${returnFalse}
   fi
}

function os_get_process_count {
   # Return number of processes running which match the provided regular expressions.
   # >>> os_get_process_count "${regex}"
   # regex: Regular expression to match to returned 'ps -ef' lines.
   # *Example*
   # ```
   # n=$(os_get_process_count ".*smon.*")
   # echo "${n} Oracle SMON Processes Found"
   # ```
   ${arcRequireBoundVariables}
   typeset regex x
   debug3 "os_get_process_count: $*"
   regex="${1}"
   ps -ef | grep "${1}" | egrep -v "grep" | debugd2
   x=$(ps -ef | grep "${1}" | egrep -v "grep" | wc -l | tr -d ' ')
   debug3 "x=${x}"
   echo ${x}
   if (( ${x} )); then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function os_create_process {
   # Create one or more temporary idle processes, typically used for integration and testing purposes.
   # >>> os_create_process "process_name" run_seconds instance_count
   # process_name: Name of process to create.
   # run_seconds: Number of seconds to run process.
   # instance_count: Number of instances of process to create.
   ${arcRequireBoundVariables}
   typeset max_processes process_name run_seconds instance_count processShell myDir
   max_processes=20
   process_name="${1}"
   run_seconds=${2:-10}
   instance_count=${3:-1}
   # Background processes run with bash don't show up with ps -ef and therefore can't be counted.
   processShell="$(_os_get_any_shell_but_bash)"
   if [[ -z "${processShell}" ]]; then
      _osThrowError "processShell undefined: os_create_process"
      return 
   fi
   (
   cat <<EOF
#!${processShell}

sleep ${run_seconds}
rm "${arcTmpDir}/${process_name}" 2> /dev/null

EOF
   ) > "${arcTmpDir}/${process_name}"
   cat "${arcTmpDir}/${process_name}" | debugd2
   myDir="$(pwd)"
   cd "${arcTmpDir}"
   chmod u+x "${process_name}"
   i=0
   while (( ${i} < ${instance_count} )); do
      ((i=i+1))
      debug3 "Spawning new process (${i}): ${process_name}"
      "./${process_name}" &
      (( ${i} >= ${max_processes} )) && break
   done
   cd "${myDir}"
}

function _os_get_any_shell_but_bash {
   if boot_is_program_found "/tmp/arcsh"; then
      echo "/tmp/arcsh"
   elif boot_is_program_found "sh"; then
      which sh 
   elif boot_is_program_found "/bin/sh"; then
      echo "/bin/sh"
   elif boot_is_program_found "ksh"; then
      which ksh
   elif boot_is_program_found "/usr/bin/ksh"; then
      echo "/usr/bin/ksh"
   else 
      _utlThrowError "Couldn't locate a non bash shell: _os_get_any_shell_but_bash"
   fi 
}

function _osThrowError {
   # Error handler for os.sh module.
   # >>> _osThrowError "errorText"
   throw_error "arcshell_os.sh" "${1}"
}
