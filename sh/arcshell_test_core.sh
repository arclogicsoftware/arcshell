#!/bin/bash 

# Copyright 2019 Arclogic Software

arcHome= 
. "${HOME}/.arcshell"

typeset regex tmpFile core_file
regex="${2:-".*"}"

(
cat <<EOF
arcHome=
. "${HOME}/.arcshell"
EOF
) | unittest_header -stdin

tmpFile="$(mktempf)"
while read core_file; do
   echo "Testing "${core_file}"..."
   cp /dev/null "${tmpFile}"
   # unittest_test -shell "/bin/bash" "${core_file}" "${regex}" 1>> "${tmpFile}" 2>> "${tmpFile}"
   unittest_test -shell "/usr/bin/ksh" "${core_file}" "${regex}" 1>> "${tmpFile}" 2>> "${tmpFile}"
   if (( $(grep "failed=0" "${tmpFile}" | wc -l) != 1 )); then
      mv "${tmpFile}" "${arcHome}/sh/core/$(basename "${core_file}").FAILED"
   fi
   # unittest_test -shell "/usr/bin/ksh" "${1}" "${regex}"
done < <(find "${arcHome}/sh/core" -type f -name "arcshell_*.sh")

unittest_cleanup

exit 0

