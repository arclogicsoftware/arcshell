
# module_name="Scheduler"
# module_about="Easily create scheduled tasks."
# module_version=1
# module_image="clock-1.png"
# copyright_notice="Copyright 2019 Arclogic Software"

_schDir="${arcTmpDir}/_arcshell_scheduler"
mkdir -p "${_schDir}/tasks"

# ToDo: Disable/enable using regex match.
# ToDo: Scheduled jobs report.
# ToDo: Wrap process in another script and obtain more control over knowing if process is still running (start/end times, duration,...).
# ToDo: A wrapper would also fix the Korn shell problem shown below in the notes.

function __readmeScheduler {
   cat <<EOF
# ArcShell Scheduler

This module runs scheduled tasks from your scheduled task folders.

## Schedules

To create a schedule create a new directory in one of the 'schedules' folders. This is the name of the schedule. Then add a 'schedule.cfg' file to configure the schedule.

## Tasks

To create a task just drop an executable file in one of the folders.

## Notes

1) You must load the ArcShell environment in each task file if you are using Korn shell. This is optional with Bash shell. Korn shell does not export the core library functions.
2) Scheduled task files should have unique names.

EOF
}

function test_file_setup {
   (
   cat <<EOF
echo "Time, got the time"
EOF
   ) > "${arcHome}/schedules/01m/test_task.sh"
   chmod 700 "${arcHome}/schedules/01m/test_task.sh"
}

function test_file_teardown {
   sch_delete_task "test_task.sh"
}

function __setupArcShellScheduler {
   _schPropogateSchedules
}

function sch_delete_task {
   # Deletes all matching task files and associated references.
   # >>> sch_delete_task "task_name"
   # task_name: Name of task file.
   ${arcRequireBoundVariables}
   debug3 "sch_delete_task: $*"
   typeset task_name 
   task_name="${1}"
   find "${_schDir}" -type f -name "${task_name}*" -exec rm {} \;
   find "${arcHome}/schedules" -type f -name "${task_name}" -exec rm {} \;
   find "${arcGlobalHome}/schedules" -type f -name "${task_name}" -exec rm {} \;
   find "${arcUserHome}/schedules" -type f -name "${task_name}" -exec rm {} \;
}

function arcshell_check_schedules {
   # Checks schedules and runs tasks. Called by the ArcShell daemon process.
   # arcshell_check_schedules
   ${arcRequireBoundVariables}
   typeset schedule_name config_file schedule
   while read schedule_name; do 
      config_file=$(_schReturnConfigFilePath "${schedule_name}")
      if [[ ! -f "${config_file}" ]]; then
         log_error -2 -logkey "scheduler" "Config file not found: ${config_file}: arcshell_check_schedules"
         continue
      fi
      schedule= 
      . "${config_file}"
      if is_truthy "${schedule:-0}"; then
         _schProcessSchedule "${schedule_name}"
      fi
   done < <(sch_list_schedules)
   ${returnTrue} 
}

function test_arcshell_check_schedules {
   arcshell_check_schedules && pass_test || fail_test 
}

function _schReturnConfigFilePath {
   # Returns the full path to the right configuration file for this schedule.
   # >>> _schReturnConfigFilePath "schedule_name"
   ${arcRequireBoundVariables}
   typeset schedule_name 
   schedule_name="${1}"
   if [[ -f "${arcUserHome}/schedules/${schedule_name}/schedule.cfg" ]]; then
      echo "${arcUserHome}/schedules/${schedule_name}/schedule.cfg"
      ${returnTrue} 
   fi
   if [[ -f "${arcGlobalHome}/schedules/${schedule_name}/schedule.cfg" ]]; then
      echo "${arcGlobalHome}/schedules/${schedule_name}/schedule.cfg"
      ${returnTrue} 
   fi
   if [[ -f "${arcHome}/schedules/${schedule_name}/schedule.cfg" ]]; then
      echo "${arcHome}/schedules/${schedule_name}/schedule.cfg"
      ${returnTrue} 
   fi
}

function _schProcessSchedule {
   # Runs each task associated with the schedule as a background process.
   # >>> _schProcessSchedule "schedule_name"
   ${arcRequireBoundVariables}
   debug3 "_schProcessSchedule: $*"
   typeset schedule_name task_file_path task_name bg_process
   schedule_name="${1}"
   while read task_file_path; do 
      task_name="$(basename "${task_file_path}")"
      if sch_is_task_enabled "${task_name}"; then
         chmod 700 "${task_file_path}"
         "${task_file_path}" &
         bg_process=$!
         counters_set "scheduler,total_tasks_executed,${task_file_path},+1"
         log_boring -logkey "scheduler" -tags "${schedule_name}" "pid=${bg_process};file='${task_file_path}'"
      fi
   done < <(_schReturnFullTaskFilePathForSchedule "${schedule_name}")
   counters_set "scheduler,schedule_count,${schedule_name},+1"
   ${returnTrue} 
}

function test__schProcessSchedule {
   _schProcessSchedule "01m" && pass_test || fail_test 
}

function sch_is_task_enabled {
   # Return true if the given task name is both enabled and not disabled.
   # >>> sch_is_task_enabled "task_name"
   # task_name: The base name of the task file is the task name.
   ${arcRequireBoundVariables}
   debug3 "sch_is_task_enabled: $*"
   typeset task_name 
   task_name="${1}"
   if _schIsTaskEnabled "${task_name}" && ! _schIsTaskDisabled "${task_name}"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test_sch_is_task_enabled {
   sch_does_task_exist "test_task.sh" && pass_test || fail_test 
   sch_is_task_enabled "test_task.sh" && pass_test || fail_test 
   sch_disable_task "test_task.sh" && pass_test || fail_test 
   ! sch_is_task_enabled "test_task.sh" && pass_test || fail_test 
   sch_enable_task "test_task.sh" "* * * * *" && pass_test || fail_test 
   sch_is_task_enabled "test_task.sh" && pass_test || fail_test 
   sch_enable_task "test_task.sh" "5 4 * * *" && pass_test || fail_test 
   ! sch_is_task_enabled "test_task.sh" && pass_test || fail_test 
   sch_enable_task "test_task.sh" && pass_test || fail_test 
   sch_is_task_enabled "test_task.sh" && pass_test || fail_test 
   sch_disable_task "test_task.sh" && pass_test || fail_test 
   ! sch_is_task_enabled "test_task.sh" && pass_test || fail_test 
   sch_disable_task "test_task.sh" "5 4 * * *" && pass_test || fail_test 
   sch_is_task_enabled "test_task.sh" && pass_test || fail_test 
   sch_disable_task "test_task.sh" "* * * * *" && pass_test || fail_test 
   ! sch_is_task_enabled "test_task.sh" && pass_test || fail_test 
}

function _schReturnFullTaskFilePathForSchedule {
   # Returns the full path to each task associated with a schedule.
   # >>> _schReturnFullTaskFilePathForSchedule "schedule_name"
   ${arcRequireBoundVariables}
   debug3 "_schReturnFullTaskFilePathForSchedule: $*"
   typeset schedule_name task_file_base_name  
   schedule_name="${1}"
   while read task_file_base_name; do
      _schReturnTaskFilePath "${schedule_name}" "${task_file_base_name}"
   done < <(_schReturnTaskFileBaseNamesForSchedule "${schedule_name}")
}

function _schIsTaskEnabled {
   # Return true if the given task name is enabled.
   # >>> _schIsTaskEnabled "task_name"
   # task_name: The base name of the task file is the task name.
   ${arcRequireBoundVariables}
   debug3 "_schIsTaskEnabled: $*"
   typeset task_name 
   task_name="${1}"
   if ! [[ -f "${_schDir}/tasks/${task_name}.enabled" ]]; then 
      debug3 "_schIsTaskEnabled: True"
      ${returnTrue} 
   fi
   . "${_schDir}/tasks/${task_name}.enabled"
   if is_truthy "${task_enabled:-1}"; then
      debug3 "_schIsTaskEnabled: True"
      ${returnTrue} 
   else
      debug3 "_schIsTaskEnabled: False"
      ${returnFalse} 
   fi
}

function _schIsTaskDisabled {
   # Return true if the given task name is disabled.
   # >>> _schIsTaskDisabled "task_name"
   # task_name: The base name of the task file is the task name.
   ${arcRequireBoundVariables}
   debug3 "_schIsTaskDisabled: $*"
   typeset task_name 
   task_name="${1}"
   ! [[ -f "${_schDir}/tasks/${task_name}.disabled" ]] && ${returnFalse} 
   . "${_schDir}/tasks/${task_name}.disabled"
   if is_truthy "${task_disabled:-0}"; then
      debug3 "_schIsTaskDisabled: True"
      ${returnTrue} 
   else
      debug3 "_schIsTaskDisabled: True"
      ${returnFalse} 
   fi
}

function _schPropogateSchedules {
   # Cascades schedule directories down to every tier.
   # >>> _schPropogateSchedules
   ${arcRequireBoundVariables}
   typeset schedule_name 
   while read schedule_name; do
      if ! [[ -d "${arcGlobalHome}/schedules/${schedule_name}" ]]; then
         mkdir "${arcGlobalHome}/schedules/${schedule_name}"
      fi
   done < <(file_list_dirs "${arcHome}/schedules")
   while read schedule_name; do
      if ! [[ -d "${arcUserHome}/schedules/${schedule_name}" ]]; then
         mkdir "${arcUserHome}/schedules/${schedule_name}"
      fi
   done < <(file_list_dirs "${arcGlobalHome}/schedules")
}

function sch_list_schedules {
   # Returns the list of available schedules.
   # >>> sch_list_schedules [-l]
   case "${1:-}" in 
      "-l") _schListSchedulesLong ;;
      *) _schListSchedules ;;
   esac
}

function _schListSchedules {
   # Returns the list of available schedules.
   # >>> _schListSchedules
   (
   file_list_dirs "${arcHome}/schedules"
   file_list_dirs "${arcGlobalHome}/schedules"
   file_list_dirs "${arcUserHome}/schedules"
   ) | sort -u
}

function _schListSchedulesLong {
   # Return a long listing of schedules with included tasks.
   # >>> _schListSchedulesLong
   printf "%-50s %-10s %-10s\n" "Task" "Schedule"  "Status"
   #str_repeat "-" 72
   while read schedule_name; do
      while read task_name; do
         if sch_is_task_enabled "${task_name}"; then
            printf "%-50s %-10s %-10s\n" "${task_name}" "${schedule_name}"  "Enabled"
         else
            printf "%-50s %-10s %-10s\n" "${task_name}" "${schedule_name}"  "Disabled"
         fi
      done < <(_schReturnTaskFileBaseNamesForSchedule "${schedule_name}")
   done < <(sch_list_schedules)
}

function sch_reset_tasks {
   # Resets all of the enabled/disable settings for the node.
   # >>> sch_reset_tasks
   ${arcRequireBoundVariables}
   find "${_schDir}/tasks" -type f -exec rm {} \;
}

function sch_enable_task {
   # Enables a task.
   # >>> sch_enable_task "task_name" ["truthy_value"]
   # task_name:
   # truthy_value:
   ${arcRequireBoundVariables}
   debug3 "sch_enable_task: $*"
   typeset task_name task_enabled_truthy_value
   task_name="${1}"
   task_enabled_truthy_value="${2:-1}"
   if sch_does_task_exist "${task_name}"; then
      echo "task_enabled=\"${task_enabled_truthy_value}\"" > "${_schDir}/tasks/${task_name}.enabled"
      rm "${_schDir}/tasks/${task_name}.disabled" 2> /dev/null
      ${returnTrue} 
   else
      log_error -2 -logkey "scheduler" "Task not found: ${task_name}: sch_enable_task"
      ${returnFalse} 
   fi
}

function sch_disable_task {
   # Disables a task.
   # >>> sch_disable_task "task_name" ["truthy_value"]
   # task_name:
   # truthy_value:
   ${arcRequireBoundVariables}
   debug3 "sch_disable_task: $*"
   typeset task_name task_disabled_truthy_value
   task_name="${1}"
   task_disabled_truthy_value="${2:-1}"
   if sch_does_task_exist "${task_name}"; then
      echo "task_disabled=\"${task_disabled_truthy_value}\"" > "${_schDir}/tasks/${task_name}.disabled"
      rm "${_schDir}/tasks/${task_name}.enabled" 2> /dev/null
      ${returnTrue} 
   else
      log_error -2 -logkey "scheduler" "Task not found: ${task_name}: sch_disable_task"
      ${returnFalse} 
   fi
}

function sch_disable_all_tasks {
   # Disable all tasks.
   # >>> sch_disable_all_tasks
   ${arcRequireBoundVariables}
   typeset task_name
   while read task_name; do
      sch_disable_task "${task_name}"
   done < <(sch_list_tasks)
}

function sch_enable_all_tasks {
   # Enable all tasks.
   # >>> sch_enable_all_tasks
   ${arcRequireBoundVariables}
   typeset task_name
   while read task_name; do
      sch_enable_task "${task_name}"
   done < <(sch_list_tasks)
}

function _schReturnTaskFilePath {
   # Returns the relevant task file for the given schedule.
   # >>> _schReturnTaskFilePath "schedule_name" "task_file"
   ${arcRequireBoundVariables}
   utl_raise_invalid_option "_schReturnTaskFilePath" "(( $# == 2 ))" "$*" && ${returnFalse} 
   typeset schedule_name task_file
   schedule_name="${1}"
   task_file="${2}"
   if [[ -f "${arcUserHome}/schedules/${schedule_name}/${task_file}" ]]; then
      echo "${arcUserHome}/schedules/${schedule_name}/${task_file}"
   elif [[ -f "${arcGlobalHome}/schedules/${schedule_name}/${task_file}" ]]; then
      echo "${arcGlobalHome}/schedules/${schedule_name}/${task_file}"
   elif [[ -f "${arcHome}/schedules/${schedule_name}/${task_file}" ]]; then
      echo "${arcHome}/schedules/${schedule_name}/${task_file}"
   else
      log_error -2 -logkey "scheduler" "Task file not found: $*"
   fi
}

function sch_does_task_exist {
   # Return true if the task name exists.
   # >>> sch_does_task_exist "task_name"
   # task_name: Base name of task file.
   ${arcRequireBoundVariables}
   debug3 "sch_does_task_exist: $*"
   typeset task_name 
   task_name="${1}"
   if sch_list_tasks | grep "^${task_name}$" 1> /dev/null; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function sch_list_tasks {
   # Returns a list of the unique task names.
   # >>> sch_list_tasks
   ${arcRequireBoundVariables}
   debug3 "sch_list_tasks: $*"
   typeset task_file 
   (
   while read task_file; do
      basename "${task_file}"
   done < <(find "${arcHome}/schedules" -type f 
      find "${arcGlobalHome}/schedules" -type f 
      find "${arcUserHome}/schedules" -type f 
      ) 
   ) | grep -v "schedule.cfg" | sort -u
}

function _schReturnTaskFileBaseNamesForSchedule {
   # Returns unique list of short file names for all files for schedule.
   # >>> _schReturnTaskFileBaseNamesForSchedule "schedule_name"
   ${arcRequireBoundVariables}
   typeset schedule_name
   schedule_name="${1}"
   (
   if [[ -d "${arcHome}/schedules/${schedule_name}" ]]; then
      file_list_files "${arcHome}/schedules/${schedule_name}"
   fi
   if [[ -d "${arcGlobalHome}/schedules/${schedule_name}" ]]; then
      file_list_files "${arcGlobalHome}/schedules/${schedule_name}"
   fi
   if [[ -d "${arcUserHome}/schedules/${schedule_name}" ]]; then
      file_list_files "${arcUserHome}/schedules/${schedule_name}"
   fi
   ) | grep -v "schedule.cfg" | sort -u
}

function test__schReturnTaskFileBaseNamesForSchedule {
   _schReturnTaskFileBaseNamesForSchedule "01m" | assert -l ">=2"
}

function _schDoesScheduleExist {
   # Return true if schedule exists.
   # >>> _schDoesScheduleExist "schedule_name"
   ${arcRequireBoundVariables}
   typeset schedule_name 
   schedule_name="${1}"
   if [[ -d "${arcHome}/schedules/${schedule_name}" ]]; then
      ${returnTrue} 
   elif [[ -d "${arcGlobalHome}/schedules/${schedule_name}" ]]; then
      ${returnTrue} 
   elif [[ -d "${arcUserHome}/schedules/${schedule_name}" ]]; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function test__schDoesScheduleExist {
   _schDoesScheduleExist "01m" && pass_test || fail_test 
}

function _schRaiseScheduleNameNotFound {
   # Throw error and return true if a schedule does not exist.
   # >>> _schRaiseScheduleNameNotFound "schedule_name"
   ${arcRequireBoundVariables}
   typeset schedule_name
   schedule_name="${1}"
   if ! _schDoesScheduleExist "${schedule_name}"; then
      log_error -2 -logkey "scheduler" "Schedule not found: $*"
      ${returnTrue} 
   else
      ${returnFalse}       
   fi
}

function test__schRaiseScheduleNameNotFound {
   _schRaiseScheduleNameNotFound "9m" 2>&1 | assert_match "ERROR"
}

