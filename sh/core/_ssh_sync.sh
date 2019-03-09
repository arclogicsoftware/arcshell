
typeset stagingDir source_file 

_ssh_source_file="${_ssh_source_file:-}"
_ssh_sync_to_dir="${_ssh_sync_to_dir:-}"
_ssh_sync_delete=${_ssh_sync_delete:-0}

#set -x

function _throwSSHSyncError {
   # Returns an error message to standard error.
   # >>> _throwSSHSyncError "errorText"
   # errorText: Error message text.
   ${arcRequireBoundVariables}
   throw_error "_ssh_sync.sh" "${1}"
}

if [[ -z "${_ssh_source_file:-}" ]]; then 
	_throwSSHSyncError "Source file not defined"
	${exitFalse}
fi

if ! [[ -f "${_ssh_source_file}" ]]; then
	_throwSSHSyncError "Source file not found: '${_ssh_source_file}'"
	${exitFalse}
fi

if [[ ! -d "${_ssh_sync_to_dir}" ]]; then
   _throwSSHSyncError "Directory does not exist: ${_ssh_sync_to_dir}"
   ${exitFalse}
fi 

if boot_is_dir_within_dir "$(dirname ${_ssh_source_file})" "${_ssh_sync_to_dir}" && (( ${_ssh_sync_delete} )); then
   _throwSSHSyncError "Remove the delete option to sync to this folder."
   ${exitFalse}
fi

stagingDir="${_ssh_sync_to_dir}-$$"
# We need to make sure we are starting with an empty directory.
rm -rf "${stagingDir}" 2> /dev/null
if ! mkdir -p "${stagingDir}"; then
   _throwSSHSyncError "Failed to create directory: ${stagingDir}"
   ${exitFalse} 
fi
if ! cp "${_ssh_source_file}" "${stagingDir}"; then
   _throwSSHSyncError "Failed to copy '${_ssh_source_file}' to '${stagingDir}'" 
   exit 1
fi
cd "${stagingDir}" || exit 1
source_file="$(ls)"
if ! [[ -f "${source_file:-}" ]]; then
	_throwSSHSyncError "Failed to identify sync file (1): $(ls): $(pwd)"
	${exitFalse}
fi
if boot_is_file_gz_zipped "${source_file}"; then
	gunzip "${source_file}"
elif boot_is_file_compressed "${source_file}"; then
	uncompress "${source_file}"
fi
# There should only be one file in the staging directory.
source_file="$(ls)"
if ! [[ -f "${source_file}" ]]; then
	_throwSSHSyncError "Failed to identify sync file (2): $(ls): $(pwd)"
	${exitFalse}
fi
if boot_is_file_archive "${source_file}"; then
	tar -xf "${source_file}"
	rm "${source_file}"
fi
typeset dirName
dirName="$(ls)"
if ! [[ -d "${dirName}" ]]; then
	_throwSSHSyncError "Failed to identify directory from sync file: $(ls): $(pwd)"
	${exitFalse}
fi
echo "Syncing './${dirName}/' to '${_ssh_sync_to_dir}'"
if (( ${_ssh_sync_delete} )); then
   rsync --times --perms --progress --delete --recursive "./${dirName}/" "${_ssh_sync_to_dir}" | sed '0,/^$/d'
else
   rsync --times --perms --progress --recursive "./${dirName}/" "${_ssh_sync_to_dir}" | sed '0,/^$/d'
fi
cd ..
rm -rf "${stagingDir}"
rm "${_ssh_source_file}"
${exitTrue}

