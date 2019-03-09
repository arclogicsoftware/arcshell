
typeset stagingDir source_file 

_ssh_source_file="${_ssh_source_file:-}"
_ssh_mount_as_dir="${_ssh_mount_as_dir:-}"
_ssh_mount_force=${_ssh_mount_force:-0}

function _throwSSHMountError {
   # Returns an error message to standard error.
   # >>> _throwSSHMountError "errorText"
   # errorText: Error message text.
   ${arcRequireBoundVariables}
   throw_error "_ssh_mount.sh" "${1}"
}

if [[ -z "${_ssh_source_file:-}" ]]; then 
	_throwSSHMountError "Source file not defined"
	${exitFalse}
fi

if ! [[ -f "${_ssh_source_file}" ]]; then
	_throwSSHMountError "Source file not found: '${_ssh_source_file}'"
	${exitFalse}
fi

if (( ${_ssh_mount_force} )) && [[ -d "${_ssh_mount_as_dir:-}" ]]; then
   echo "Forcing mount by removing the existing '${_ssh_mount_as_dir}' directory first."
   rm -rf "${_ssh_mount_as_dir}"
fi

if [[ -d "${_ssh_mount_as_dir}" ]]; then
   _throwSSHMountError "Directory already exists: '${_ssh_mount_as_dir}'"
   ${exitFalse}
fi 

stagingDir="${_ssh_mount_as_dir}-$$"
if ! mkdir -p "${stagingDir}"; then
   _throwSSHMountError "Failed to create directory: ${stagingDir}"
   ${exitFalse} 
fi

if ! mkdir -p "${_ssh_mount_as_dir}"; then
   _throwSSHMountError "Failed to create '${_ssh_mount_as_dir}'"
   exit 1
fi
rm -rf "${_ssh_mount_as_dir}"

if ! cp "${_ssh_source_file}" "${stagingDir}"; then
   _throwSSHMountError "Failed to copy '${_ssh_source_file}' to '${stagingDir}'" 
   exit 1
fi

cd "${stagingDir}" || exit 1

source_file="$(ls)"
if ! [[ -f "${source_file}" ]]; then
	_throwSSHMountError "Failed to identify mount file (1): $(ls): $(pwd)"
	${exitFalse}
fi
if boot_is_file_gz_zipped "${source_file}"; then
   gunzip "${source_file}"
elif boot_is_file_compressed "${source_file}"; then
   uncompress "${source_file}"
fi
source_file="$(ls)"
if ! [[ -f "${source_file}" ]]; then
   _throwSSHSyncError "Failed to identify mount file (2): $(ls): $(pwd)"
   ${exitFalse}
fi
if boot_is_file_archive "${source_file}"; then
   tar -xf "${source_file}"
   rm "${source_file}"
fi
typeset dirName
dirName="$(ls)"
if ! [[ -d "${dirName}" ]]; then
	_throwSSHMountError "Failed to identify directory from mount file: $(ls): $(pwd)"
	${exitFalse}
fi
mv "${dirName}" "${_ssh_mount_as_dir}"
cd ..
rm -rf "${stagingDir}"
rm "${_ssh_source_file}"
${exitTrue}

