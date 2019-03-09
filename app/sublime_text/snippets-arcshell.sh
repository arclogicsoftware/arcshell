#!/bin/bash

arcHome=
. ~/.arcshell

. "${arcHome}/app/sublime_text/sublime_text.sh"

sublime_text_generate_snippet "\${returnTrue}" "RT"
sublime_text_generate_snippet "\${returnFalse}" "RF"
sublime_text_generate_snippet "&& pass_test || fail_test" "PT"
sublime_text_generate_snippet "&& fail_test || pass_test" "FT"

sublime_text_generate_snippet "function function_name {
   # 
   # >>> function_name
   \${arcRequireBoundVariables}
   debug2 \"\$*: function_name\"
   typeset x
   :
   \${returnTrue}
}

function test_function_name {
   :
}
" "NF"

function sublime_text_generate_arcshell_snippets {
   # Generate the snippets for all documented ArcShell functions in the core library.
   # >>> sublime_text_generate_arcshell_synopses_snippets
   ${arcRequireBoundVariables}
   typeset x f snippet tabTrigger
   [[ -n "${1:-}" ]] && regex="${1}"
   while read x; do
      debug0 "Generating snippets for ${x}..."
      while read f; do
         snippet="${f}"
         tabTrigger="$(echo "${f}" | cut -d" " -f1)"
         debug0 "-> ${tabTrigger}"
         sublime_text_generate_snippet "${snippet}" "${tabTrigger}"
      done < <(doceng_get_synopsis "${x}" | grep "^>" | sed "s/^> //" | sed "s/^\"//" | sed "s/^\$(//")
   done < <(find "${arcHome}/sh" -type f -name "*.sh")
}

sublime_text_generate_arcshell_snippets

