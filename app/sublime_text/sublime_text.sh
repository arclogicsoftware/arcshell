

sublime_text_snippets="/media/sf_Snippets"

# Path to the folder copy Snippets to.
sublime_text_snippets="${sublime_text_snippets:-}"
[[ -z "${sublime_text_snippets:-}" ]] && ${returnFalse} 

function __sublimeTextSnippetTemplate {
   # Returns the template used to create a snippet.
   # >>> __sublimeTextSnippetTemplate
   typeset scope 
   scope="source.shell"
   cat <<EOF
<snippet>
<content><![CDATA[
${snippet:-} 
]]></content>
<tabTrigger>${tabTrigger:-}</tabTrigger>
<description></description>
<scope>${scope:-}</scope>
</snippet>
EOF
}

function sublime_text_generate_snippet {
   # Generates a new or updates an existing snippet.
   # >>> sublime_text_generate_snippet "snippet" "trigger"
   # snippet: Snippet text.
   # trigger: String which triggers the snippet.
   ${arcRequireBoundVariables}
   snippet="$(echo "${1}" | _sublimeTextEscapeSnippetText)"
   tabTrigger="${2}"
   __sublimeTextSnippetTemplate > "${sublime_text_snippets}/${tabTrigger}.sublime-snippet"
}

function test_sublime_text_generate_snippet {
   sublime_text_generate_snippet "foo bar" "foo"
   echo "${sublime_text_snippets}/foo.sublime-snippet" | assert -f "Snippet file should exist."
   rm "${sublime_text_snippets}/foo.sublime-snippet" 
}

function _sublimeTextEscapeSnippetText {
   # Add backslashes to the some characters, .[]()*$, and return string.
   # >>> _sublimeTextEscapeSnippetText "snippet"
   ${arcRequireBoundVariables}
   typeset x 
   while IFS= read -r x; do
      echo "${x:-}" | sed 's#\([\\\$]\)#\\\1#g'
   done
}

function _sublimeThrowError {
   # Returns error message to standard error.
   # >>> _sublimeThrowError "error_message"
   throw_error "sublime_text.sh" "${1}"
}

