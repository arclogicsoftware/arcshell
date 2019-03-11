
# module_name="ArcShell Updater"
# module_about="Update ArcShell using the current image."
# module_version=1
# copyright_notice="Copyright 2019 Arclogic Software"

typeset delete_option target_dir source_dir

if [[ ! -f "./arcshell_update.sh" ]]; then
   cd "$(dirname "$0")" 
fi

. "$(pwd)/sh/arcshell_boot.sh"

if ! (( ${arcshellBootstrapLoaded:-0} )); then
   echo "Failed to load 'arcshell_boot.sh'"
   exit 1
fi

${arcRequireBoundVariables}

function _arcshellUpdateThrowError {
   throw_error "arcshell_update.sh" "${1}"
}

if [[ $0 != "arcshell_update.sh" && $0 != "./arcshell_update.sh" && $0 != $(pwd)/arcshell_update.sh ]]; then
   _arcshellUpdateThrowError "\$0 is '$0'. Switch to the arcshell_update.sh directory and then execute './arcshell_update.sh'"
   ${exitFalse}
fi

if ! (( ${arcshellBootstrapLoaded:-0} )); then
   _arcshellUpdateThrowError "arcshell_boot.sh is not loaded!"
fi

if [[ ! -d "${HOME}" ]]; then
   _arcshellUpdateThrowError "\${HOME} is either not set or set to a directory that does not exist: ${HOME}"
   ${exitFalse}
fi

# Load the current arcshell environment if it is found.
if [[ ! -f "${HOME}/.arcshell" ]]; then
   _arcshellUpdateThrowError "'${HOME}/.arcshell' was not found. This program is only run if ArcShell is already installed."
   ${exitFalse}
fi

. "${HOME}/.arcshell"

if [[ "$(pwd)" -ef "${arcHome}" ]]; then
   _arcshellUpdateThrowError "You can't run 'arcshell_update.sh' from the current ArcShell home."
   ${exitFalse}
else
   source_dir="$(pwd)"
   target_dir="${arcHome}"
   if [[ -d "${target_dir}" ]]; then
      log_boring -logkey "arcshell" -tags "update" "Updating '${target_dir}' from '${source_dir}'."
      rsync_dir ${delete_option:-0} -ssh "${arcNode}" -exclude ".git,user,.gitattributes,.gitignore,nohup.out" "${source_dir}" "${target_dir}"
      #rsync --times --perms --progress --stats --recursive "${source_dir}/" "${target_dir}"
      cd "${arcHome}" || ${exitFalse}
      "./arcshell_setup.sh"
      rm -rf "${source_dir}"
   fi
   ${exitTrue}
fi

