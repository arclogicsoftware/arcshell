
# Copyright 2019 Arclogic Software

# Load the current arcshell environment if it is found.
if [[ ! -f "${HOME}/.arcshell" ]]; then
   exit 0
fi

. "${HOME}/.arcshell" 2> /dev/null

${arcRequireBoundVariables:-}

if which arcshell.sh 1> /dev/null; then
   arcshell.sh daemon stop
fi

[[ -d "${arcUserHome:-}" ]] && rm -rf "${arcUserHome}"
[[ -d "${arcGlobalHome:-}" ]] && rm -rf "${arcGlobalHome}"
[[ -d "${arcHome:-}" ]] && rm -rf "${arcHome}"

find "${HOME}" -type f -name ".arcshell" -exec rm {} \;
find "${HOME}" -type f -name "arcshell.err" -exec rm {} \;

exit 0