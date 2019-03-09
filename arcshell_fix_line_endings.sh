

arcHome="$(pwd)"

[[ ! -d "${arcHome:-}" ]] && exit 1

typeset file 

while read file; do
   if grep $'\r' "${file}" 1> /dev/null; then
      echo "Fixing '${file}'"
      cat "${file}" | tr -d '\015' > "${file}~"
      mv "${file}~" "${file}"
   fi
done < <(find "${arcHome}" -type f | egrep "\.sh|\.md|\.awk|\.txt|\.config")

while read file; do
   if grep $'\r' "${file}" 1> /dev/null; then
      echo "Fixing '${file}'"
      cat "${file}" | tr -d '\015' > "${file}~"
      mv "${file}~" "${file}"
   fi
done < <(find "${arcHome}/config" -type f)

while read file; do
   if grep $'\r' "${file}" 1> /dev/null; then
      echo "Fixing '${file}'"
      cat "${file}" | tr -d '\015' > "${file}~"
      mv "${file}~" "${file}"
   fi
done < <(find "${arcGlobalHome}/config" -type f)


exit 0


