
function arcshell_pull_reporting {
   # Pull status from a node, should present everything going on for up to past week or so. 
   # Reports should be archived.
   # This would be good for nodes which are not activley communicating with the deployment node.
   # Also good for sending data to team admins.
}

function random_tips_here_and_there {
   :
}

function directory_as_an_object_library {
   # dir_set_dir
   # dir_backup
   # dir_compare_to ~30 days
   # 
}

function removes_unit_test_functions_from_file {
   :
   # Merge program would move unittests from files to stand-alone file and can 
   # keep that file updated. Tests are addative to the file. Tests could also be
   # merged back into the current file.
}

function shell_code_performance_profiler {
   :
}

function pushover_integration {
	# https://pushover.net/
	:
}

function coding_exercise_bitcoin_automatic_trader {
   :
}

function coding_exercise_roullete_tester {
   :
}

function coding_exercise_quizzer {
   # Write a quiz program using menu module, other modules.
   :
}

# Jan. 16, 2018
function _throw_syntax_error {
   #  Returns syntax error text and usage to standard error.
   # >>> _throw_syntax_error "errorText: $*: functionName"

   # Return errorText to STDERR.
   # Try to find functionName within the files which make up ArcShell.
   # Return function doclines to STDERR.
}

function logs_hourly_debug_summary {
   # ToDo: Add more detail here, log if there were any errors, notices, etc...
   # ToDo: Add total number of lines, compare previous hour to this hour and
   # show any new lines.
   ${arcRequireBoundVariables}
   typeset debugLine
   debug0 "arccore: info: Hourly Debug Summary"
   (
   while read -r debugLine; do
      lineCount=$(echo "${debugLine}" | cut -d" " -f1)
      lineText=$(echo "${debugLine}" | cut -d" " -f2- | str_trim_line -stdin)
      echo "${lineText} (${lineCount}x)"
   done < <(grep "$(date +'%Y-%m-%d %H:')" ${debugFile} | egrep "DEBUG0|DEBUG1" | cut -d ":" -f4- | sort | uniq -c | str_trim_line | sort -nr)
   ) | debugd0
}

