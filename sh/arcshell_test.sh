#!/bin/bash 

# Copyright 2019 Arclogic Software

arcHome= 
. "${HOME}/.arcshell"

typeset regex 
regex="${2:-".*"}"

(
cat <<EOF
arcHome=
. "${HOME}/.arcshell"
EOF
) | unittest_header -stdin

unittest_test -shell "/bin/bash" "${1}" "${regex}"
#unittest_test -shell "/usr/bin/ksh" "${1}" "${regex}"

unittest_cleanup

exit 0

