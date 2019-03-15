
function __usageCollectServerLoad {
   cat <<EOF
Collects os load metrics and monitor for os load thresholds.
EOF
} 

arcHome=
. "${HOME}/.arcshell"

# Only runs on the a primary install.
boot_is_aux_instance && exit 0

typeset os_load
os_load=$(os_return_load)

echo "${os_load}" | threshold_monitor -config "os_load.cfg" "os_load"

echo "server_load|${os_load}" | stats_read -tags "os" "os_load" 

exit 0
