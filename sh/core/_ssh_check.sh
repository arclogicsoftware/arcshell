
returnTrue="return 0"
returnFalse="return 1"
_ssh_check_test_text=
_ssh_check_fix=${_ssh_check_fix:-0}

while (( $# > 0)); do
   case "${1}" in
      "-fix"|"-f") _ssh_check_fix=1 ;;
      *) break ;;
   esac
   shift
done

function _ssh_check_pass {
   echo "[OK]    ${_ssh_check_test_text}"
}

function _ssh_check_fail {
   echo "[FAIL]  ${_ssh_check_test_text}"
}

function _ssh_check_fixed {
   echo "[FIXED] ${_ssh_check_test_text}"
}

function _ssh_check_setup {
   _ssh_check_test_text="${1} "
}

function _ssh_check_is_dir_writable_by_non_owner {
   typeset d x
   d="${1}"
   x=$(ls -al ${d} 2>/dev/null | grep "\ \.$" | cut -d" " -f1)
   if [[ "${x:5:1}" == "w" ]]; then
      ${returnTrue}
   fi
   if [[ "${x:8:1}" == "w" ]]; then
      ${returnTrue}
   fi
   ${returnFalse}
}

function _ssh_check_is_file_secure {
   typeset f x
   f="${1}"
   x=$(ls -l ${f} 2>/dev/null | cut -d" " -f1)
   if (( $(echo "${x:1:9}" | grep "r.*------" | wc -l) )); then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

_ssh_check_setup "${HOME} directory not writable by group or others"
if ! _ssh_check_is_dir_writable_by_non_owner "${HOME}"; then
   _ssh_check_pass 
else 
   if (( ${_ssh_check_fix} )); then
      chmod 755 "${HOME}"
      _ssh_check_fixed
   else
      _ssh_check_fail
   fi
fi

_ssh_check_setup ".ssh directory exists"
if [[ -d "${HOME}/.ssh" ]]; then
   _ssh_check_pass 
else 
   if (( ${_ssh_check_fix} )); then
      mkdir "${HOME}/.ssh"
      _ssh_check_fixed
   else
      _ssh_check_fail
   fi
fi 

if [[ -d "${HOME}/.ssh" ]]; then
   _ssh_check_setup ".ssh directory not writable by group or others"
   if ! _ssh_check_is_dir_writable_by_non_owner "${HOME}/.ssh"; then
      _ssh_check_pass 
   else
      if (( ${_ssh_check_fix} )); then
         chmod 700 "${HOME}/.ssh"
         _ssh_check_fixed
      else
         _ssh_check_fail 
      fi 
   fi
fi

_ssh_check_setup "authorized_keys file exists"
if [[ -f "${HOME}/.ssh/authorized_keys" ]]; then
   _ssh_check_pass
else
   if (( ${_ssh_check_fix} )); then
      touch "${HOME}/.ssh/authorized_keys" 
      _ssh_check_fixed
   else
      _ssh_check_fail
   fi
fi

if [[ -f "${HOME}/.ssh/authorized_keys" ]]; then
   _ssh_check_setup "authorized_keys is secure"
   if _ssh_check_is_file_secure "${HOME}/.ssh/authorized_keys"; then
      _ssh_check_pass
   else
      if (( ${_ssh_check_fix} )); then
         chmod 600 "${HOME}/.ssh/authorized_keys"
         _ssh_check_fixed
      else
         _ssh_check_fail
      fi
   fi
fi

_ssh_check_setup "known_hosts exists"
if [[ -f "${HOME}/.ssh/known_hosts" ]]; then
   _ssh_check_pass 
else 
   if (( ${_ssh_check_fix} )); then
      touch "${HOME}/.ssh/known_hosts"
      _ssh_check_fixed
   else
      _ssh_check_fail
   fi
fi

if [[ -f "${HOME}/.ssh/known_hosts" ]]; then
   _ssh_check_setup "known_hosts is secure"
   if _ssh_check_is_file_secure "${HOME}/.ssh/known_hosts"; then
      _ssh_check_pass
   else
      if (( ${_ssh_check_fix} )); then
         chmod 600 "${HOME}/.ssh/known_hosts"
         _ssh_check_fixed
      else
         _ssh_check_fail
      fi
   fi
fi

_ssh_check_setup "public key file exists"
if [[ -f "${HOME}/.ssh/id_rsa.pub" ]]; then
   _ssh_check_pass 
else
   if (( ${_ssh_check_fix} )); then
      rm "${HOME}/.ssh/id_rsa" 2> /dev/null
      ssh-keygen -f "${HOME}/.ssh/id_rsa" -t rsa -N ''
      _ssh_check_fixed
   else
      _ssh_check_fail 
   fi
fi

_ssh_check_setup "public key file is secure"
if [[ -f "${HOME}/.ssh/id_rsa.pub" ]]; then
   if _ssh_check_is_file_secure "${HOME}/.ssh/id_rsa.pub"; then
      _ssh_check_pass
   else
      if (( ${_ssh_check_fix} )); then
         chmod 600 "${HOME}/.ssh/id_rsa.pub"
         _ssh_check_fixed
      else
         _ssh_check_fail
      fi
   fi
fi

_ssh_check_setup "private key file exists"
if [[ -f "${HOME}/.ssh/id_rsa" ]]; then
   _ssh_check_pass 
else
   if (( ${_ssh_check_fix} )); then
      rm "${HOME}/.ssh/id_rsa.pub" 2> /dev/null
      ssh-keygen -f id_rsa -t rsa -N ''
      _ssh_check_fixed
   else
      _ssh_check_fail
   fi
fi

_ssh_check_setup "private key file is secure"
if [[ -f "${HOME}/.ssh/id_rsa" ]]; then
   if _ssh_check_is_file_secure "${HOME}/.ssh/id_rsa"; then
      _ssh_check_pass
   else
      if (( ${_ssh_check_fix} )); then
         chmod 600 "${HOME}/.ssh/id_rsa"
         _ssh_check_fixed
      else
         _ssh_check_fail
      fi
   fi
fi


