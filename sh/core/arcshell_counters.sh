
# module_name="Counters"
# module_about="A fast counter management mechanism."
# module_version=1
# module_image="add-1.png"
# copyright_notice="Copyright 2019 Arclogic Software"

function __readmeCounters {
   cat <<EOF
> There is never enough time to do it right first time, but there is always time to go back and fix it when it breaks. -- Anonymous

# Counters

**A fast counter management mechanism.**

Counters provide you with an easy way to instrument your code with a minimal impact on performance.

Counters are "eventually" consistent. A background process runs every minute and tally's the latest sets of values. 
EOF
}

function __exampleCounters {

   # Deletes a counter group and all associated files.
   counters_delete_group "foo"

   # Creates a new counter called 'sheep' in the foo group.
   counters_set "foo,sheep,+1"

   # Increments the counter by 1.
   counters_set "foo,sheep,+1"

   # This will return 0. The increment in last step is not
   # available until 'counters_update' is called.
   counters_get "foo,sheep"

   # For examples to return correct values below we need
   # to set this to 0. Normally most recent file is not
   # included in 'counters_update' but when this is 0 it is.
   _g_counterSafeMode=0

   # Set the counter to ten.
   counters_set "foo,sheep,=10"

   # Force update and check value. Will return 10.
   counters_update
   counters_get "foo,sheep"

   # Let's add an animal to the group.
   counters_set "foo,cow,=3"

   # Subtract a cow.
   counters_set "foo,cow,-1"

   # Return all counter values in the group. Returns 10 and 2.
   counters_update
   counters_get "foo"

   counters_delete_group "foo"
   counters_get_group "foo"

   # This returns 0. 0 returned when a counter does not exist.
   counters_get "animals,horses"
}

_counterDir="${arcTmpDir}/_arcshell_counters"
mkdir -p "${_counterDir}/tmp"

_g_counterSafeMode=1

function test_file_setup {
   _g_counterSafeMode=0
}

function _countersUpdateDirtyGroups {
   # Update counters for all groups with pending counter updates.
   # >>> _countersUpdateDirtyGroups 
   ${arcRequireBoundVariables}
   debug3 "_countersUpdateDirtyGroups: $*"
   typeset counter_group 
   if lock_aquire -try 5 -term 600 "_countersUpdateDirtyGroups"; then
      while read counter_group; do
         _countersUpdateGroup "${counter_group}"
      done < <(_counterListDirtyGroups)
      lock_release "_countersUpdateDirtyGroups"
   fi
}

function _counterListDirtyGroups {
   # Return a list of the groups which have data that needs to be processed.
   # >>> _counterListDirtyGroups
   file_list_files "${_counterDir}/tmp" | ${arcAwkProg} -F "." '{print $1}' | sort -u
}

function test_counter_set_no_expression {
   counters_delete_group "foo" && pass_test || fail_test 
   counters_set "foo,100"
   counters_update
   counters_get "foo" | assert 100 "Sign was not used, = assumed, should be 100."
   counters_set "foo,-10"
   counters_update
   counters_get "foo" | assert 90 "'-' sign was used, 100-10 should be 90."
   counters_set "foo,10"
   counters_update
   counters_get "foo" | assert 10 "Sign was not used, = is assumed, should be 10."
}

function test_counters_set {
   counters_delete_group "foo" && pass_test || fail_test 
   echo "${_counterDir}/foo.csv" | assert ! -f "Counter was deleted, .csv file should not exist."
   counters_set "foo,bar,=62"
   counters_set "foo,bar,+10"
   counters_get "foo,bar" | assert 0 "Counter returns zero until counters have been updated."
   # Force all pending files to process for the sake of testing.
   counters_update
   # BUG: Failure message not showing here.
   echo "${_counterDir}/foo.csv" | assert -f ".csv file should exist after counters have been updated."
   counters_get "foo,bar" | assert 72 "Counter value should be 72."
   counters_set "foo,bar,-1"
   counters_update
   counters_get "foo,bar" | assert 71 "Counter value should be 71."
}

function counters_set {
   # Sets or updates a counter value.
   # >>> counters_set "counter_group,counter_id[,counter_id],[operator]counter_value"
   ${arcRequireBoundVariables}
   typeset counter_group
   counter_group="${1%%,*}"
   echo "$*" >> "${_counterDir}/tmp/${counter_group}.$$.$(date +"%Y%m%d%H%M")"
   ${returnTrue} 
} 

function counters_get_group {
   # Return all of the counter values for the group. Format is 'counter=value'.
   # >>> counters_get_group "counter_group"
   ${arcRequireBoundVariables}
   typeset counter_group 
   counter_group="${1}"
   if [[ -f "${_counterDir}/${counter_group}.csv" ]]; then
      cat "${_counterDir}/${counter_group}.csv"
   fi
}

function counters_raise_group_does_not_exist {
   # Return true and error if the counter group does not exist.
   # >>> counters_raise_group_does_not_exist "counter_group"
   ${arcRequireBoundVariables}
   typeset counter_group
   counter_group="${1}"
   if ! counters_does_group_exist "${counter_group}"; then
      log_error -2 -logkey "counters" "Counter group does not exist: $*"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function counters_does_group_exist {
   # Return true if the counter group exists.
   # >>> counters_does_group_exist "counter_group"
   ${arcRequireBoundVariables}
   typeset counter_group
   counter_group="${1}"
   if [[ -f "${_counterDir}/${counter_group}.csv" ]]; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function counters_get {
   # Return a counter value.
   # >>> counters_get "counter_group,counter"
   # counter_group: Counter group.
   # counter: A counter within the group.
   ${arcRequireBoundVariables}
   debug3 "counters_get: $*"
   typeset counters_group pattern
   counter_group="${1%%,*}"
   if [[ -f "${_counterDir}/${counter_group}.csv" ]]; then
      pattern=$(echo "${1}" | awk 'gsub(/, +/,",") gsub(/ +,/,",")')
      grep "^${pattern},=" "${_counterDir}/${counter_group}.csv" | awk -F"," '{print $NF}' | sed 's/=//'
   else
      echo 0
   fi
}

function counters_delete_group {
   # Remove a counter group.
   # >>> counters_delete_group "counter_group"
   # counter_group: Counter group.
   ${arcRequireBoundVariables}
   typeset counter_group 
   counter_group="${1}"
   find "${_counterDir}/tmp" -name "${counter_group}.*" -exec rm {} \;
   find "${_counterDir}" -name "${counter_group}.csv" -type f -exec rm {} \;
   ${returnTrue} 
}

function test_counters_delete_group {
   counters_delete_group "foo" && pass_test || fail_test 
}

function counters_update {
   # Update all pending counters by processing the .tmp files containing counter data.
   # >>> counters_update
   ${arcRequireBoundVariables}
   _countersUpdateDirtyGroups
}

function counters_force_update {
   #
   #
   counters_update
}

function _countersUpdateGroup {
   # Process pending counter updates for a group.
   # >>> _countersUpdateGroup "counter_group"
   # counter_group: Counter group.
   ${arcRequireBoundVariables}
   debug3 "_countersUpdateGroup: $*"
   typeset counter_group file_name tmpFile
   counter_group="${1}"
   tmpFile="$(mktempf)"
   touch "${_counterDir}/${counter_group}.csv"
   # This must be first to ensure a 'value' type counter records the last value.
   counters_get_group "${counter_group}" > "${tmpFile}"
   (
   while read file_name; do
      cat "${file_name}" && rm "${file_name}"
   done < <(_countersReturnTmpFiles "${counter_group}")
   ) >> "${tmpFile}"
   ${arcAwkProg} -f "${arcHome}/sh/core/_counter.awk" "${tmpFile}" > "${_counterDir}/${counter_group}.csv"
   rm "${tmpFile}"
}

function _countersReturnTmpFiles {
   # Returns the list temp files storing counter updates for a group.
   # >>> _countersReturnTmpFiles "group"
   # group: Counter group.
   ${arcRequireBoundVariables}
   typeset counter_group currentDateTimeString
   counter_group="${1}"
   if (( ${_g_counterSafeMode} )); then
      # Add a short delay if we are near the top of the minute, otherwise we 
      # might filter the previous minute and grab the current file.
      (( $(dt_second) > 57 )) && sleep 5
      currentDateTimeString="$(date +"%Y%m%d%H%M")"
      find "${_counterDir}/tmp" -type f -name "${counter_group}.*" | egrep -v "${currentDateTimeString}"
   else 
      find "${_counterDir}/tmp" -type f -name "${counter_group}.*"
   fi
}

function test_file_teardown {
   counters_delete_group "foo"
   counters_delete_group "counters"
   _g_counterSafeMode=1
}

