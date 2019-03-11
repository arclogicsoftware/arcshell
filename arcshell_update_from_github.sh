

arcHome=
. ~/.arcshell 

__github_download_url="${1:-"https://github.com/arclogicsoftware/arcshell/archive/master.zip"}"

if [[ ! -f "${HOME}/.arcshell" ]]; then
   throw_error "$0" "${HOME}/.arcshell is not found. Make sure ArcShell is already installed: $*: $0"
   exit 1
fi

typeset tmpDir new_directory starting_dir
tmpDir="$(mktempd)"
starting_dir="$(pwd)"
cd "${tmpDir}" || ${returnFalse} 

boot_raise_program_not_found "wget" && ${returnFalse} 
boot_raise_program_not_found "unzip" && ${returnFalse} 

wget "${__github_download_url}" 
unzip "${tmpDir}/"*".zip"

if (( $(file_list_dirs "${tmpDir}" | wc -l) != 1 )); then
   log_error -2 -logkey "arcshell" "Downloaded file contained more than one root directory: $*: _arcDownloadAndUpdateFromGitHubMasterZipFile"
   ${returnFalse} 
fi
new_directory="$(file_list_dirs "${tmpDir}")"
cd "${new_directory}" || ${returnFalse} 
find "${tmpDir}/${new_directory}" -type f -name "*.sh" -exec chmod 700 {} \;
./arcshell_update.sh 
cd "${starting_dir}"
rm -rf "${tmpDir}"
exit 0