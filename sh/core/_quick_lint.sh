
_lint_file="${arcHome}/sh/core/arcshell_utl.sh"

function _check_bad_things {
   while read x; do
      grep "${x}" "${_lint_file}"
   done < <(_bad_things)
}

function _bad_things {
   # Regular expressions to search for which might be an error.
   cat <<'EOF'
#>>>
>>>_
#.*>>>[a-z].*
#.*>>>.*\$(
EOF
}

function _check_double_bracket_spacing {
   # Common syntax error, no space before ]] or after [[.
   grep "\[\[" "${_lint_file}" |  grep -v "\[\[ "
   grep "]]" "${_lint_file}" | grep -v " ]]" 
}

_check_bad_things
_check_double_bracket_spacing

