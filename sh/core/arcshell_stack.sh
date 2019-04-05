
# module_name="Data Stacks"
# module_about="Create and manage small data stacks which operate a little like arrays."
# module_version=1
# module_image="layers.png"
# copyright_notice="Copyright 2019 Arclogic Software"

[[ -z "${arcTmpDir}" ]] && return
stackDir=${arcTmpDir}/_arcshell_stacks && mkdir -p "${stackDir}"

function __readmeDataStacks {
   cat <<EOF
> When you don't create things, you become defined by your tastes rather than ability. Your tastes only narrow & exclude people. So create. -- Why The Lucky Stiff

# Data Stacks

**Create and manage small data stacks which operate a little like arrays.**

EOF
}

function __todoStacks {
   cat <<EOF
## Implement return values.

## Create stack groups. 

## Ability to pop and perform other actions for all of the stacks in the group.

EOF
}

function stack_create {
   # Create a new stack if it does not exist.
   # >>> stack_create "stack_name"
   ${arcRequireBoundVariables}
   typeset stackName
   stackName="${1}"
   str_raise_not_a_key_str "stack_create" "${stackName}" && ${returnFalse} 
   if ! stack_exists "${stackName}"; then
      mkdir "${stackDir}/${stackName}"
      touch "${stackDir}/${stackName}/.stack"
      chmod 600 "${stackDir}/${stackName}/.stack"
   fi
}

function stack_add {
   # Add one or more values to the stack.
   # - Stack is created if it doesn't exist.
   # - Function can read multiple values from standard input.
   # >>> stack_add [-stdin] "stack_name" ["stack_value"]
   ${arcRequireBoundVariables}
   typeset stackName stackValue 
   [[ "${1:-}" == "-stdin" ]] && shift
   stackName="${1}"
   stackValue="${2:-}"
   _stackAutoCreate "${stackName}"
   if (( $# == 2 )); then
      echo "${stackValue}" >> "${stackDir}/${stackName}/.stack"
   else
      cat >> "${stackDir}/${stackName}/.stack"
   fi
}

function stack_list {
   # Return the list of values on stack.
   # >>> stack_list "stack_name"
   ${arcRequireBoundVariables}
   typeset stackName
   stackName="${1}"
   if stack_exists "${stackName}"; then
      cat "${stackDir}/${stackName}/.stack"
   fi
}

function stack_delete {
   # Delete a stack if it exists.
   # >>> stack_delete "stack_name"
   ${arcRequireBoundVariables}
   debug3 "stack_delete: $*"
   typeset stackName
   stackName="${1}"
   if stack_exists "${stackName}"; then
      rm -rf "${stackDir}/${stackName}"
   fi
}

function stack_copy {
   # Make a copy of a stack.
   # >>> stack_copy "source_stack" "target_stack"
   ${arcRequireBoundVariables}
   typeset sourceStackName
   sourceStackName="${1}"
   targetStackName="${2}"
   if stack_exists "${sourceStackName}"; then
      stack_delete "${targetStackName}"
      cp -rp "${stackDir}/${sourceStackName}" "${stackDir}/${targetStackName}"
   else
      _stackThrowError "sourceStackName does not exist: $*: stack_copy"
   fi
}

function _stackAutoCreate {
   #
   # >>> _stackAutoCreate "stack_name"
   ${arcRequireBoundVariables}
   typeset stackName 
   stackName="${1}"
   if ! stack_exists "${stackName}"; then
      stack_create "${stackName}"
   fi
}

function stack_return_last_value {
   # Return the most recent value on the stack.
   ${arcRequireBoundVariables}
   debug3 "stack_return_last_value: $*"
   typeset stackName
   stackName="${1}"
   tail -1 "${stackDir}/${stackName}/.stack"
}

function stack_remove_last_value {
   # Remove the most recent value on the stack.
   # >>> stack_remove_last_value "stack_name"
   ${arcRequireBoundVariables}
   debug3 "stack_remove_last_value: $*"
   typeset stackName
   stackName="${1}"
   sed '$d' "${stackDir}/${stackName}/.stack" > "${stackDir}/${stackName}/.stack~"
   mv "${stackDir}/${stackName}/.stack~" "${stackDir}/${stackName}/.stack"
}

function stack_return_first_value {
   # Return the oldest value on the stack.
   ${arcRequireBoundVariables}
   debug3 "stack_return_first_value: $*"
   typeset stackName
   stackName="${1}"
   head -1 "${stackDir}/${stackName}/.stack"
}

function stack_remove_first_value {
   # Remove the oldest value on the stack.
   # >>> stack_remove_first_value "stack_name"
   ${arcRequireBoundVariables}
   debug3 "stack_remove_first_value: $*"
   typeset stackName
   stackName="${1}"
   sed '1d' "${stackDir}/${stackName}/.stack" > "${stackDir}/${stackName}/.stack~"
   mv "${stackDir}/${stackName}/.stack~" "${stackDir}/${stackName}/.stack"
}

function stack_pop_last_value {
   # Return and then remove the most recent value from the stack.
   # >>> stack_pop_last_value "stack_name"
   ${arcRequireBoundVariables}
   debug3 "stack_pop_last_value: $*"
   typeset stackName
   stackName="${1}"
   if stack_has_values "${stackName}"; then
      stack_return_last_value "${stackName}"
      stack_remove_last_value "${stackName}"
      ${returnTrue} 
   else
      ${returnFalse}
   fi
}

function stack_pop_first_value {
   # Return and then remove the oldest value on the stack.
   # >>> stack_pop_first_value "stack_name"
   ${arcRequireBoundVariables}
   debug3 "stack_pop_first_value: $*"
   typeset stackName
   stackName="${1}"
   if stack_has_values "${stackName}"; then
      stack_return_first_value "${stackName}"
      stack_remove_first_value "${stackName}"
      ${returnTrue} 
   else
      ${returnFalse}
   fi
}

function stack_count {
   # Return the count of items on the stack.
   ${arcRequireBoundVariables}
   debug3 "stack_count: $*"
   typeset stackName
   stackName="${1}"
   file_line_count "${stackDir}/${stackName}/.stack" 
}

function stack_has_values {
   # Return true if the stack has any values.
   # >>> stack_has_values "stack_name"
   ${arcRequireBoundVariables}
   debug3 "stack_has_values: $*"
   typeset stackName
   stackName="${1}"
   if [[ -s "${stackDir}/${stackName}/.stack" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function stack_exists {
   # Return true if the stack exists.
   # >>> stack_exists "stack_name"
   ${arcRequireBoundVariables}
   debug3 "stack_exists: $*"
   typeset stackName
   stackName="${1}"
   if [[ -d "${stackDir}/${stackName}" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function stack_clear {
   # Clear the stack of all values.
   # >>> stack_clear "stack_name"
   ${arcRequireBoundVariables}
   debug3 "stack_clear: $*"
   typeset stackName
   stackName="${1}"
   _stackAutoCreate "${stackName}"
   cp /dev/null "${stackDir}/${stackName}/.stack"
}

function stack_value_count {
   # Return a count of the number of times a value appears in the stack.
   # >>> stack_value_count "stack_name" "stack_value"
   ${arcRequireBoundVariables}
   debug3 "stack_value_count: $*"
   typeset stackName stackValue
   stackName="${1}"
   stackValue="${2}"
   if stack_has_values "${stackName}"; then
      x=$(grep "^${stackValue}$" "${stackDir}/${stackName}/.stack" | wc -l)
   else
      x=0
   fi
   echo ${x}
}

function _stackThrowError {
   # Error handler for this library.
   # >>> _stackThrowError "errorText"
   throw_error "arcshell_stack.sh" "${1}"
}

