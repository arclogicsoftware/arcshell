

# module_name="Packager"
# module_about="Package a directory for deployment or distribution to remote nodes."
# module_version=1
# module_image="gift.png"
# copyright_notice="Copyright 2019 Arclogic Software"

[[ -z "${arcTmpDir}" ]] && return
_pkgDir="${arcTmpDir}/_arcshell_pkg"
mkdir -p "${_pkgDir}"

mkdir -p "${arcHome}/config/packages"
mkdir -p "${arcGlobalHome}/config/packages"

# Global packages will always be copied to local packages directory if they do not exist.
# This will be set to 1 once it has been checked within the current session.
_g_pkgWorkingFile=

function __setupArcShellPkg {
   :
}

function pkg_show {
   # Returns the working file and connection details if they have been set.
   # >>> pkg_show
   echo "Current working file is '${_g_pkgWorkingFile:-}'."
}

function pkg_set {
   # Sets the file you will be working with.
   # >>> pkg_set "package_file"
   # package_file: (tar, tar.gz, or tar.Z) file which contains a single top level directory and contents.
   ${arcRequireBoundVariables}
   typeset file_path
   utl_raise_invalid_option "pkg_set" "(( $# == 1 ))" "$*" && ${returnFalse} 
   if [[ -f "${1}" ]]; then
      file_path="${1}"
   elif [[ -f "${arcGlobalHome}/config/packages/${1}" ]]; then
      file_path="${arcGlobalHome}/config/packages/${1}"
   else  [[ -f "${arcUserHome}/config/packages/${1}" ]]; 
      file_path="${arcUserHome}/config/packages/${1}"
   fi
   if file_raise_file_not_found "${file_path:-}"; then
      _g_pkgWorkingFile=
      ${returnFalse} 
   else 
      if [[ ! "${file_path}" -ef "${_g_pkgWorkingFile}" ]]; then
         _g_pkgWorkingFile="${file_path}"
         log_terminal "Setting active package to '${file_path}'."
      fi
      ${returnTrue} 
   fi
}

function pkg_unset {
   # Unset the ssh connection and file you are working with.
   # >>> pkg_unset 
   _g_sshConnection=
   _g_pkgWorkingFile=
}

function pkg_dir {
   # Create a compressed archive file of a directory.
   # >>> pkg_dir [-exclude "X"] [-saveto "X"] [package_dir=$(pwd)]
   # -exclude: A list of directories to exclude from the package.
   # -saveto: Directory to write the file to.
   # package_dir: Path to top level directory that you want to package.
   ${arcRequireBoundVariables}
   debug3 "pkg_dir: $*"
   typeset dir_to_save_package_to dir_to_package excluded_dirs dir_name d excludeOptions
   dir_to_package="$(pwd)"
   dir_to_save_package_to="$(pwd)/.."
   excluded_dirs=
   while (( $# > 0)); do
      case "${1}" in
         "-saveto") shift; dir_to_save_package_to="${1}" ;;
         "-exclude") shift; excluded_dirs="$(utl_format_single_item_list "${1}")" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "pkg_dir" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   (( $# == 1 )) && dir_to_package="${1}"
   utl_raise_dir_not_found "${dir_to_package}" && ${returnFalse}
   log_terminal "log_text"  "Packaging '${dir_to_package}'"
   dir_name="$(basename "${dir_to_package}")"
   file_raise_dir_not_writable "${dir_to_save_package_to}" && ${returnFalse} 
   excludeOptions="--exclude ${dir_to_save_package_to}/${dir_name}.tar"
   if [[ -n "${excluded_dirs:-}" ]]; then
      while read d; do
         excludeOptions="--exclude ${d} ${excludeOptions}"
      done < <(echo "${excluded_dirs}" | str_split_line ",")
   fi
   debug3 "excludeOptions=${excludeOptions}"
   debug3 "tar cfC ${dir_to_save_package_to}/${dir_name}.tar ${dir_to_package}/.. ${excludeOptions} ./${dir_name}"
   tar cfC "${dir_to_save_package_to}/${dir_name}.tar" "${dir_to_package}/.." ${excludeOptions} "./${dir_name}"
   chmod 600 "${dir_to_save_package_to}/${dir_name}.tar"
   utl_zip_file "${dir_to_save_package_to}/${dir_name}.tar"
   target_file="$(file_realpath "$(utl_zip_get_last_file_path)")"
   pkg_set "${target_file}"
   log_terminal "'${dir_to_package}' is saved to '${target_file}'"
   ${returnTrue}
}

function test_pkg_dir {
   # ToDo: Tests needed here.
   fail_test " Tests needed for this function."
}

function pkg_ssh_mount {
   # Mount a tar.gz or tar.Z file "as" a directory on one or more SSH end points.
   # >>> pkg_ssh_mount [-force,-f] [-target,-t "X"] [-ssh,-s "X"] ["package_file"]
   # -force: 0 or 1. Force mount even if target directory already exists when 1.
   # -target: Directory to mount the file "as" not "to". Note, this may change the top level directory name in the file being mounted!
   # -ssh: SSH user@hostname, alias, tag, or group.
   # package_file: (tar, tar.gz, or tar.Z) file which contains a single top level directory and contents.
   ${arcRequireBoundVariables}
   debug3 "pkg_ssh_mount: $*"
   typeset force_option target_directory  ssh_connection package_file ssh_node errors
   force_option=0
   target_directory=
   ssh_connection="${_g_sshConnection:-}"
   package_file="${_g_pkgWorkingFile:-}"
   err=0
   while (( $# > 0)); do
      case "${1}" in
         "-ssh"|"-s") shift; ssh_connection="${1}" ;;
         "-force"|"-f") force_option=1 ;;
         "-target"|"-t") shift; target_directory="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_empty_var "SSH connection is not set. Use -ssh option." "${ssh_connection}" && ${returnFalse}
   utl_raise_invalid_option "pkg_ssh_mount" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   (( $# == 1 )) && package_file="${1}"
   file_raise_file_not_found "${package_file}" && ${returnFalse} 
   ssh_set "${ssh_connection}" || ${returnFalse} 
   if [[ -z "${target_directory:-}" ]]; then
      target_directory="\${HOME}/$(file_get_file_root_name "${package_file}")"
   fi
   while read ssh_node; do 
      _sshIsNodeLocalHost "${ssh_node}" && continue
      if ! _pkgMountAsDirectory; then \
         ${force_option} \
         "${ssh_node}" \
         "${package_file}" \
         "${target_directory}" && \
         ((errors=errors+1))
      fi
      log_terminal "Package mounted to '${target_directory}'."
   done < <(_sshListMembers "${ssh_connection}")
   if (( ${errors} )); then
      ${returnFalse} 
   else
      ${returnTrue} 
   fi
}

function _pkgMountAsDirectory {
   # Mount the working package file as a directory on a single node. 
   # >>> _pkgMountAsDirectory force_option "ssh_node" "package_file" "target_directory"
   # ssh_node: SSH user@hostname.
   # package_file: (tar, tar.gz, or tar.Z) file which contains a single top level directory and contents.
   # target_directory: Directory to mount the package "as". 
   ${arcRequireBoundVariables}
   typeset _ssh_mount_force ssh_node package_file target_directory tmpFile source_file_basename allow_local
   debug3 "_pkgMountAsDirectory: $*"
   _ssh_mount_force=${1}
   ssh_node="${2}"
   package_file="${3}"
   target_directory="${4}"
   source_file_basename="$(basename "${package_file}")"
   if ! _sshCopyToNode "${ssh_node}" "${package_file}"; then
      _pkgThrowError "Failed to copy '${package_file}' to '\${HOME}' on '${ssh_node}': $*: _pkgMountAsDirectory"
      ${returnFalse}
   fi
   tmpFile="$(mktempf)"
   (
   cat "${arcHome}/sh/arcshell_boot.sh"
   cat <<EOF
_ssh_source_file="\${HOME}/${source_file_basename}"
_ssh_mount_as_dir="${target_directory}"
_ssh_mount_force="${_ssh_mount_force}"
EOF
   cat "${arcHome}/sh/core/_ssh_mount.sh"
   ) > "${tmpFile}"
   chmod 700 "${tmpFile}"
   if _sshRunFile ${allow_local:-1} "${ssh_node}" "${tmpFile}"; then
      rm "${tmpFile}"
      log_terminal "Package mounted as ${target_directory}."
      ${returnTrue}
   else
      rm "${tmpFile}"
      _pkgThrowError "Failed to mount package: $*: _pkgMountAsDirectory"
      ${returnFalse}
   fi
}

function _pkgSync {
   # Sync the package file to an existing directory.
   # >>> _pkgSync delete_option "ssh_node" "package_file" "target_directory"
   # delete_option: Delete non-matching files from the remote node.
   # ssh_node: SSH user@hostname.
   # package_file: (tar, tar.gz, or tar.Z) file which contains a single top level directory and contents.
   # target_directory: Directory to mount the package "as". 
   ${arcRequireBoundVariables}
   typeset target_directory tmpFile source_file_basename ssh_node delete_option package_file allow_local
   debug3 "_pkgSync: $*"
   utl_raise_invalid_option "_pkgSync" "(( $# == 4 ))" "$*" && ${returnFalse} 
   delete_option=${1}
   ssh_node="${2}"
   package_file="${3}"
   target_directory="${4}"
   source_file_basename="$(basename "${package_file}")"
   if ! _sshCopyToNode "${ssh_node}" "${package_file}"; then
      _pkgThrowError "Failed to copy '${package_file}' to '\${HOME}' on '${ssh_node}': $*: _pkgSync"
      ${returnFalse}
   fi
   tmpFile="$(mktempf)"
   (
   cat "${arcHome}/sh/arcshell_boot.sh"
   cat <<EOF
_ssh_source_file="\${HOME}/${source_file_basename}"
_ssh_sync_to_dir="${target_directory}"
_ssh_sync_delete=${delete_option}
EOF
   cat "${arcHome}/sh/core/_ssh_sync.sh"
   ) > "${tmpFile}"
   if _sshRunFileAtNode ${allow_local:-0} "${ssh_node}" "${tmpFile}"; then
      rm "${tmpFile}"
      log_terminal "Package synced to ${target_directory}."
      ${returnTrue}
   else
      rm "${tmpFile}"
      _pkgThrowError "Failed to sync package: $*: _pkgSync"
      ${returnFalse}
   fi
}

function pkg_sync {
   # Sync a package to a directory on remote nodes.
   # >>> pkg_sync [-ssh "X"] [-delete,-d] [-package,-p "X"] "target_directory"
   # -ssh: SSH user@hostname, alias, tag, or group.
   # -delete: Delete non-matching files from the remote nots.
   # -package: (tar, tar.gz, or tar.Z) file which contains a single top level directory and contents.
   # target_directory: Directory to mount the package "as". 
   ${arcRequireBoundVariables}
   debug3 "pkg_sync: $*"
   typeset target_directory delete_option node_name ssh_connection package_file error_count
   error_count=0
   delete_option=
   target_directory=
   ssh_connection="${_g_sshConnection:-}"
   package_file="${_g_pkgWorkingFile:-}"
   while (( $# > 0)); do
      case "${1}" in
         "-ssh"|"-s") shift; ssh_connection="${1}" ;;
         "-package"|"-p") shift; package_file="${1}" ;;
         "-delete"|"-d") delete_option=" -delete " ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "pkg_sync" "(( $# == 1 ))" "$*" && ${returnFalse} 
   file_raise_file_not_found "${package_file:-}" && ${returnFalse} 
   ssh_set "${ssh_connection:-}" || ${returnFalse} 
   target_directory="${1}"
   while read node_name; do 
      _sshIsNodeLocalHost "${node_name}" && continue
      if ! _pkgSync ${delete_option} "${node_name}" "${package_file}" "${target_directory}" < /dev/null; then
         _pkgThrowError "Error syncing '${package_file}' to '${node_name}:$*: '${target_directory:-}': pkg_sync"
         ((error_count=error_count+1))
      fi
   done < <(_sshListMembers "${ssh_connection}")
   if (( ${error_count} )); then
      ${returnFalse} 
   else
      ${returnTrue} 
   fi
}

function pkg_list {
   # Return the list of known packages.
   # >>> pkg_list ["regex"]
   # regex: Filter results to those matching regular expression.
   ${arcRequireBoundVariables}
   typeset regex object_name 
   regex="${1:-.*}"
   while read object_name; do
      config_return_object_path "packages" "${object_name}"
   done < <(config_list_all_objects "packages" | egrep "${regex}")
}

function _pkgThrowError {
   # Error handler for this library.
   # >>> _pkgThrowError "error_message"
   throw_error "arcshell_pkg.sh" "${1}"
}


