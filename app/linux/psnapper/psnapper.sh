

. "${HOME}/.arcshell"

psn  | egrep  ".*\|.*\|.*\|.*" | utl_remove_blank_lines -stdin | \
   log_info -stdin -logkey "os" -tags "psnapper" "psnapper results"

exit