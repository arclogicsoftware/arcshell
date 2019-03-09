
. ${arcHome}/sh/core/arcshell_shfile.sh

source_file="${arcHome}/sh/core/arcshell_contact_groups.sh"
test_file="${arcHome}/sh/test/arcshell_contact_groups.sh"

shfile_set "${test_file}"

typeset f tmpFile l in_function

tmpFile="$(mktempf)"

in_function=0
(
while IFS= read -r l; do
   echo "${l}"
   if echo "${l}" | grep "^function " 1>/dev/null; then
      f="$(echo "${l}" | awk '{print $2}')"
      in_function=1
   elif (( ${in_function} )); then
      if [[ "${l}" == "}" ]]; then
         in_function=0 
         if shfile_does_function_exist "test_${f}"; then
            echo ""
            shfile_return_function_def "test_${f}"
            shfile_remove_function "test_${f}"
         fi
      fi
   fi
done < <(cat "${source_file}")
) > "${source_file}~"

rm "${tmpFile}"

