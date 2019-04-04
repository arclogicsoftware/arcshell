
# module_name="Tar"
# module_about="This module is used to to work with tar files."
# module_version=1
# module_image="archive-2.png"
# copyright_notice="Copyright 2019 Arclogic Software"

_tarDir="${arcTmpDir}/_arcshell_tar"
mkdir -p "${_tarDir}"

function __readmeTar {
   cat <<EOF
# Tar

**This module is used to to work with tar files.**
EOF
}

function __setupArcShellTar {
   :
}

function tar_open {
   # Open a .tar, .tar.gz, or .tar.Z file in an existing directory.
   # >>> tar_open "tar_file" "directory"
   ${arcRequireBoundVariables}
   debug2 "tar_open: $*"
   typeset tar_file directory tmpDir myDir
   tar_file="${1}"
   file_raise_file_not_found "${tar_file}" && ${returnFalse} 
   directory="${2}"
   file_raise_dir_not_found "${directory}" && ${returnFalse} 
   tmpDir="$(mktempd)"
   cp "${tar_file}" "${tmpDir}"
   tar_file="$(find "${tmpDir}" -type f)"
   if boot_is_file_compressed "${tar_file}"; then
      uncompress "${tar_file}"
   elif boot_is_file_gz_zipped "${tar_file}"; then
      gunzip "${tar_file}"
   fi
   myDir="$(pwd)"
   cd "${tmpDir}" || ${returnFalse} 
   ! tar -xf * || ${returnFalse} 
   rm *".tar" || ${returnFalse} 
   mv * "${directory}" 
   cd "${myDir}"
   rm -rf "${tmpDir}"
}


function _tarThrowError {
   # Returns error message to standard error.
   # >>> _appThrowError "errorText"
   throw_error "arcshell_tar.sh" "${1}"
}

