

# module_name="Demo"
# module_about="Create playable command line demonstrations."
# module_version=1
# module_image="record.png"
# copyright_notice="Copyright 2019 Arclogic Software"

[[ -z "${arcTmpDir}" ]] && return

_g_demo_file="${arcTmpDir}/_arcshell_demo.tmp"
_g_demo_key_press_delay=".00"
_g_global_wait_seconds=0
_g_markdown_file="${arcTmpDir}/demo$(dt_y_m_d_h_m).md"

function demo_end {
   echo "A Markdown version of the demo and output is here: '${_g_markdown_file}'."
}

function demo_return_markdown {
   cat "${_g_markdown_file}"
}

function demo_figlet {
   if boot_is_program_found "figlet"; then
      figlet -f standard "${1}"
   else
      echo "${1}"
   fi
}

function _demoGlobalWait {
   #
   #
   ${arcRequireBoundVariables}
   #sleep ${_g_global_wait_seconds:-}
}

function demo_get_function_doc {
   # Get doc lines for specified function.
   # >>> demo_get_function_doc "file" "func"
   typeset file func
   file="${1}"
   func="${2}"
   utl_get_function_doc "${file}" "${func}"
}

function test_demo_get_function_doc {
   demo_get_function_doc "${arcHome}/sh/core/arcshell_demo.sh" "demo_get_function_doc" | assert -l 2
}

function demo_code {
   # Populates the buffer with the code you want to run but does not run it.
   # >>> demo_code [-l] "code_block" [pause_seconds]
   # code_block: Block of shell code to prepare to execute.
   ${arcRequireBoundVariables}
   typeset do_line_num 
   _demoGlobalWait
   do_line_num="-l"
   while (( $# > 0)); do
      case $1 in
         -l) do_line_num="-l"   ;;
          *) break              ;;
      esac
      shift
   done
   cp /dev/null "${_g_demo_file}"
   echo "${1}" > "${_g_demo_file}"
   echo "\`\`\`bash" >> "${_g_markdown_file}"
   demo_key ${do_line_num} "${1}"
   echo "\`\`\`" >> "${_g_markdown_file}"
   sleep ${2:-0}
}

function test_demo_code {
   demo_code '
echo xyz
echo abc
' | egrep "xyz|abc" | assert -l 2
   demo_run | egrep "xyz|abc" | assert -l 2
}

function _demoMarkdownText {
   #
   #
   cat >> "${_g_markdown_file}"
}

function _demoMarkdownCode {
   #
   #
   tmpFile="$(mktempf)"
   cat > "${tmpFile}"
   if [[ -s "${tmpFile}" ]]; then
      # Ugly hack right here.
      cat "${tmpFile}"
      (
      echo "\`\`\`bash"
      cat "${tmpFile}"
      echo "\`\`\`"
      ) >> "${_g_markdown_file}"
   fi
   rm "${tmpFile}"
}

function demo_run {
   # Runs the code in the buffer.
   # >>> demo_run -subshell
   # subshell: Runs the command as a sub-process.
   _demoGlobalWait
   if [[ -f "${_g_demo_file}" ]]; then
      if [[ "${1:-}" == "-subshell" ]]; then
         "${_g_demo_file}" 2>&1 | _demoMarkdownCode
      else
         . "${_g_demo_file}" 2>&1 | _demoMarkdownCode
      fi
   fi
}

function demo_key {
   # Display characters on the screen. Simulate typing if key delay is set.
   # This function reads standard input or \${1} parameter.
   # >>> demo_key "text" [seconds]
   # text: Text to key.
   # seconds: Number of seconds to sleep at end of command.
   ${arcRequireBoundVariables}
   typeset x l do_line_num 
   _demoGlobalWait
   do_line_num=
   line_num=0
   while (( $# > 0)); do
      case "${1}" in
         -l) do_line_num="-l" ;;
         *) break ;;
      esac
      shift
   done
   (
   while IFS= read -r x; do
      ((line_num=line_num+1))
      [[ -n "${do_line_num:-}" ]] && printf "%-2s: %s " "${line_num}"
      if (( $(echo "${_g_demo_key_press_delay} == 0" | bc -l) )); then
         printf "%s\n" "${x}"
      else
         for (( i=0; i<${#x}; i++ )); do
            printf "${x:${i}:1}"
            sleep ${_g_demo_key_press_delay}
         done
         echo ""
      fi
   done < <(echo "${1:-}")
   ) | tee -a "${_g_markdown_file}"
   sleep ${2:-0}
}

function test_demo_key {
   demo_key "1 2 3 4 5 6 7 8 9
-----------------" | egrep "1|-" | assert -l 2
}


function demo_wait {
   # Pause demo and wait for user input to continue. 
   # > demo_wait 
   ${arcRequireBoundVariables}
   printf "\n%s " "${1:-#}"
   read x < /dev/tty
}
