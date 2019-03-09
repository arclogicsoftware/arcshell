


_shfileFile=

function shfile_set {
   # Sets the working file.
   # >>> shfile_set "file"
   _shfileFile="${1}"
}

function shfile_unset {
   # Unsets the working file.
   # >>> shfile_unset
   _shfileFile=
}

function shfile_check_params {
  #
  #
  egrep "# .*:" "${_shfileFile}" | sed 's/ -/ /' | sort
}

function shfile_list_functions {
   # List all of the functions in a file.
   # >>> shfile_ls
   egrep "^function .*{" "${_shfileFile}" | awk '{print $2}'
   egrep "^[A-Z|a-z].*\(\).*{" "${_shfileFile}" | grep -v "^# " | awk '{print $1}'
   ${returnTrue} 
}

function shfile_does_function_exist {
   #
   #
   if shfile_list_functions | grep "^${1}$" 1>/dev/null; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function shfile_return_function_body {
   # Returns the function body. Removes first 3 characters which should be spaces.
   # >>> shfile_return_function_body "function name"
   ${arcRequireBoundVariables}
   typeset func_name start lines x
   func_name="${1}"
   start=$(grep -n "^function ${func_name} " "${_shfileFile}" | cut -d":" -f1)
   ((start=start+1))
   lines=$(wc -l "${_shfileFile}" | cut -d" " -f1)
   if [[ -n "${start}" && -n "${lines}" ]] && (( ${start} > 1 )); then   
      echo ""
      while IFS= read -r x; do
         if [[ "${x:0:1}" == "}" ]]; then
            break
         fi
         echo "${x}"
      done < <(sed -n "${start},${lines}p" "${_shfileFile}")
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function shfile_return_docs {
   # Returns the function documentation from a file.
   # >>> utl_get_function_doc "function name"
   ${arcRequireBoundVariables}
   typeset func_name line_no started line 
   func_name="${1}"
   line_no=0 
   started=0
   while read line; do
      ((line_no=line_no+1))
      if (( ${line_no} == 2 )) && [[ "${line:0:1}" == "#" ]]; then
         started=1
      fi
      if [[ "${line:0:1}" == "#" ]] && (( ${started} )); then
         echo "${line}"
      fi
      if [[ "${line:0:1}" != "#" ]] && (( ${started} )); then
         started=0
      fi
   done < <(utl_get_function_def "${_shfileFile}" "${func_name}" | utl_remove_blank_lines -stdin)
}

function shfile_return_function_def {
   # Returns a function definition from a file.
   # >>> shfile_return_function_def "function name"
   ${arcRequireBoundVariables}
   typeset f 
   f="${1}"
   ${arcAwkProg} -v regex="^${f}$" -f "${arcHome}/sh/core/_shReturnsFunction.awk" "${_shfileFile}"
   ${returnTrue} 
}

function shfile_remove_function {
   #
   #
   ${arcRequireBoundVariables}
   typeset f 
   f="${1}"
   ${arcAwkProg} -v regex="^${f}$" -f "${arcHome}/sh/core/_shReturnsFileWithoutFunction.awk" "${_shfileFile}" > "${_shfileFile}~"
   mv "${_shfileFile}~" "${_shfileFile}"
}

function shfile_is_function_loaded {
  # Return true if the function is loaded in the environment.
  # >>> shfile_is_function_loaded "function name"
  ${arcRequireBoundVariables}
  if [[ "${arcShellType}" == "bash" ]]; then
    type -t "${1}" 1> /dev/null && ${returnTrue} 
  elif [[ "${arcShellType}" == "ksh" ]]; then
    typeset -f "${1}" 1> /dev/null && ${returnTrue} 
  fi
  ${returnFalse} 
}


