
function __usageCheckAlerts {
   cat <<EOF
Monitor alerts and send recurring notifications when required.
EOF
} 

arcHome=
. "${HOME}/.arcshell"

alerts_check

exit 0
