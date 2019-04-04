
. "${HOME}/.arcshell"

boot_raise_program_not_found "python" && ${exitFalse}
file_raise_file_not_found "./install.sh" && ${exitFalse} 

typeset uninstall_file install_home 
install_home="${arcGlobalHome}"
while (( $# > 0)); do
  case "${1}" in
      "-global"|"-g") : ;;
      "-user"|"-u") install_home="${arcUserHome}" ;;
     *) break ;;
  esac
  shift
done
utl_raise_invalid_option "install.sh" "(( $# == 0 ))" "$*" && ${exitFalse}

if [[ -f "${arcGlobalHome}/bin/uninstall_psnapper.sh" ]]; then
   uninstall_psnapper.sh 2> /dev/null
fi

if [[ -f "${arcUserHome}/bin/uninstall_psnapper.sh" ]]; then
   uninstall_psnapper.sh 2> /dev/null
fi

uninstall_file="${install_home}/bin/uninstall_psnapper.sh"

cp /dev/null "${uninstall_file}"

tmpDir="$(mktempd)"

cd "${tmpDir}" || ${exitFalse}

wget https://github.com/tanelpoder/psnapper/archive/master.zip
unzip ./master.zip

mv "./psnapper-master/LICENSE" "./psnapper-master/psnapper-LICENSE"
mv "./psnapper-master/README.md" "./psnapper-master/psnapper-README.md"

echo "Copying files to '${install_home}/bin/'..."
while read f; do
   echo "$(basename ${f})"
   cp "${f}" "${install_home}/bin/"
   echo "rm \${install_home:-"x"}/bin/$(basename ${f})" >> "${uninstall_file}"
done < <(find "${tmpDir}" -type f | egrep -v "gitignore")

if boot_is_program_found "psn"; then 
   echo "The 'psn' utility is installed successfully."
   echo "Run '${uninstall_file}' to uninstall."
   echo "=============================================================================="
   echo "README.md"
   cat "${tmpDir}/psnapper-master/psnapper-README.md"
   echo "=============================================================================="
   echo "ArcLogic Software also recommends visiting https://blog.tanelpoder.com/."
   echo ""
   log_notice -logkey "apps" -tags "psnapper" "psnapper installed successfully."
   rm -rf "${tmpDir}"
   ${exitTrue}
else
   log_error -2 -logkey "apps" -tags "psnapper" "Failed to install psnapper. Media is in '${tmpDir}'."
   ${exitFalse}
fi
