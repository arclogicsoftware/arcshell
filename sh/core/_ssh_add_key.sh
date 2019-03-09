
# This file is called by the arcshell_ssh.sh library when adding public keys
# to the authorized_key files on either the local host or a remote host.

typeset KEYOWNER AUTHORIZED_KEYS

_ssh_public_key="${_ssh_public_key:-}"
_ssh_force_key=${_ssh_force_key:-0}

[[ -z "${_ssh_public_key:-}" ]] && exit 1

AUTHORIZED_KEYS="${HOME}/.ssh/authorized_keys"

function _ssh_add_write {
	echo "${1}"
}

function _ssh_add_get_user_host {
	echo "${_ssh_public_key}" | awk '{print $NF}' 
}

function _ssh_return_other_keys_from_authorized_key_file {
	cat "${AUTHORIZED_KEYS}" | grep -v "${KEYOWNER}$"
}

function _ssh_is_key_already_in_authorized_keys {
	if (( $(grep "${_ssh_public_key}" "${AUTHORIZED_KEYS}" | wc -l) > 0 )); then
		return 0
   else 
   	return 1
   fi
}

KEYOWNER="$(_ssh_add_get_user_host)"

if [[ "${KEYOWNER}" != "${LOGNAME}@$(hostname)" ]] && \
	[[ "${KEYOWNER}" != "${LOGNAME}@$(hostname)" ]]; then
	if ! _ssh_is_key_already_in_authorized_keys || (( ${_ssh_force_key} )); then 
		(
		_ssh_return_other_keys_from_authorized_key_file
		echo "${_ssh_public_key}"
		) > "${AUTHORIZED_KEYS}.$$"
		# Todo: mv "${AUTHORIZED_KEYS}.$$" "${AUTHORIZED_KEYS}"
		cat "${AUTHORIZED_KEYS}.$$" > "${AUTHORIZED_KEYS}"
		rm "${AUTHORIZED_KEYS}.$$"
		if _ssh_is_key_already_in_authorized_keys; then
			_ssh_add_write "Success: ${KEYOWNER} can connect to ${LOGNAME}@$(hostname) using key-based authentication."
	   else
	   	_ssh_add_write "An error occurred trying to add ${KEYOWNER}'s public key to ${LOGNAME}@$(hostname)'s authorized_keys file."
	   fi
	else 
		_ssh_add_write "Success: ${KEYOWNER}'s public key already exists in ${LOGNAME}@$(hostname)'s authorized_keys file."
	fi
else
	_ssh_add_write "Skipping, ${KEYOWNER} public key belongs to the localhost."
fi
chmod 600 "${AUTHORIZED_KEYS}"



