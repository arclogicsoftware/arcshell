
# module_name="rsync"
# module_about="A simple rsync interface."
# module_version=1
# module_image="repeat-1.png"
# copyright_notice="Copyright 2019 Arclogic Software"

function __readmeRsync {
   cat <<EOF
> The perfect kind of architecture decision is the one which never has to be made

# Rsync

**A simple rsync interface.**
EOF
}

function rsync_dir {
   # Sync 'source_dir' to 'target_dir'. 'target_dir' may be created if it does not exist.
   # >>> rsync_dir [-ssh,-s "X"] [-delete,-d] [-exclude,-e "X"] source_dir target_dir
   # -ssh: SSH user@hostname, alias, tag, or group.
   # -delete: Delete files from target not found in source.
   # -exclude: List of files and directories to exclude.
   # source_dir: Source directory to sync.
   # target_dir: Target directory to sync to. If it does not exist it is created when the parent directory exists already.
   ${arcRequireBoundVariables}
   debug3 "rsync_dir: $*"
   typeset ssh_connection  source_dir target_dir delete_option ssh_node tmpFile ssh_user errors exclude_list
   ssh_connection="${_g_sshConnection:-}"
   delete_option=0
   tmpFile="$(mktempf)"
   errors=0
   exclude_list=
   while (( $# > 0)); do
      case "${1}" in
         "-ssh"|"-s") shift; ssh_connection="${1}" ;;
         "-delete"|"-d") delete_option=1 ;;
         "-exclude"|"-e") shift; exclude_list="$(utl_format_single_item_list "${1}")" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "rsync_dir" "(( $# == 2 ))" "$*" && ${returnFalse} 
   source_dir="${1}"
   target_dir="${2}"
   file_raise_dir_not_found "${source_dir}" && ${returnFalse} 
   [[ -z "${ssh_connection:-}" ]] && ssh_connection="${arcNode}"
   exclude_file="$(mktempf)"
   echo "${exclude_list:-}" | str_split_line -stdin "," > "${exclude_file}"
   while read ssh_node; do 
      if ! _rsyncDir ${delete_option} "${ssh_node}" "${source_dir}" "${target_dir}" "${exclude_file}" </dev/null; then
         ((errors=errors+1))
      fi
   done < <(_sshListMembers "${ssh_connection}")
   rm "${exclude_file}"
   if (( ${errors} )); then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _rsyncDir {
   # Sync 'source_dir' to 'target_dir'. 'target_dir' will be created if it does not exist.
   # >>> _rsyncDir delete_option "ssh_node" "source_dir" "target_dir" "exclude_file"
   # delete_option: 0 or 1. Delete remote files if not found locally when 1.
   # ssh_node: SSH user@hostname.
   # source_dir: Source directory to sync.
   # target_dir: Target directory to sync to. If it does not exist it is created when the parent directory exists already.
   # exclude_file: File which contains list of items to exclude from the rsync.
   ${arcRequireBoundVariables}
   debug3 "_rsyncDir: $*"
   typeset ssh_node  source_dir target_dir delete_option ssh_user exclude_file
   utl_raise_invalid_option "_rsyncDir" "(( $# == 5 ))" "$*" && ${returnFalse} 
   delete_option=${1}
   if (( ${delete_option} )); then
      delete_option=" --delete"
   else
      delete_option=
   fi
   ssh_node="${2}"
   source_dir="${3}"
   target_dir="${4}"
   exclude_file="${5}"
   file_raise_dir_not_found "${source_dir}" && ${returnFalse} 
   _sshRaiseIsGroup "${ssh_node}" && ${returnFalse} 
   ssh_user="$(echo "${ssh_node}" | cut -d"@" -f1)"
   eval "$(ssh_load "${ssh_node}")"
   if _sshIsNodeLocalHost "${ssh_node}"; then
      rsync --exclude-from "${exclude_file}" --stats --progress --recursive --times --links --perms -z ${delete_option} \
         "${source_dir}/" "${target_dir}"
   elif [[ -n "${SSHPASS:-}" ]]; then
      rsync --exclude-from "${exclude_file}" --stats --progress --recursive --times --links --perms -z ${delete_option} \
         --rsh="sshpass -e ssh -l ${ssh_user}" \
         "${source_dir}/" "${ssh_node}:${target_dir}"
   else 
      if [[ -n "${node_ssh_key:-}" ]]; then
         node_ssh_key="$(_sshReturnSSHKeyFilePath "${node_ssh_key}")"
         rsync --exclude-from "${exclude_file}" -e "ssh -i "${node_ssh_key}"" --stats --progress --recursive --times --links --perms -z ${delete_option} \
         "${source_dir}/" "${ssh_node}:${target_dir}"
      else
         rsync --exclude-from "${exclude_file}" --stats --progress --recursive --times --links --perms -z ${delete_option} \
            "${source_dir}/" "${ssh_node}:${target_dir}"
      fi
   fi
   ${returnTrue} 
}
