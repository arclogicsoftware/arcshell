#!/bin/bash

. "${HOME}/.arcshell"

pct_error_rate=${1:-50}

if (( $(num_random 1 100) <= 50 )); then
   log_error -2 -logkey "cron" "cron_test.sh"
   exit 1
fi

exit
