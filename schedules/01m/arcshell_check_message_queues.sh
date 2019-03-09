
function __usageCheckArcShellMessageQueues {
	cat <<EOF
Checks the message queues and sends queued messages when set criteria is met.
EOF
} 

arcHome=
. "${HOME}/.arcshell"

! is_truthy "${messaging_enabled:-1}" && exit 0 
is_truthy "${messaging_disabled:-0}" && exit 0 

msg_check_message_queues



























