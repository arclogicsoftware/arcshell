
function __usageCollectServerLoad {
   cat <<EOF
Collects server load metrics.
EOF
} 

arcHome=
. "${HOME}/.arcshell"

boot_is_aux_instance && exit 0

echo "server_load|$(os_return_load)" | stats_read -tags "os" "server_load" 

exit 0






