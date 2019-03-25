
# module_name="Keywords"
# module_about="Manages ArcShell keywords."
# module_version=1
# module_image="sign-1.png"
# copyright_notice="Copyright 2019 Arclogic Software"

mkdir -p "${arcHome}/config/keywords"

function __readmeKeywords {
   cat <<EOF
Keywords are found in the \`\`\`\${arcHome}/config/keywords\`\`\` folder.

To change the settings for a keyword copy the keyword file to the \`\`\`\${arcGlobalHome}/config/keywords\`\`\` folder or \`\`\`\${arcUserHome}/config/keywords\`\`\` and modify it. 

Keywords can be created by placing new files in one of these two folders. We recommend keeping the number of keywords to a minimum.

When ArcShell loads a keyword it loads all files in top down order. Delivered, global, then user.

**Example of a keyword configuration file.**

Truthy values are allowable. 

Keyword configuration files are shell scripts. You can use shell to conditionally set the values.

\`\`\`
# \${arcHome}/config/keywords/critical.cfg
#
$(cat "${arcHome}/config/keywords/critical.cfg")
\`\`\`
EOF
}

function keyword_raise_not_found {
   # Raise error and return true if the keyword is not found.
   # >>> keyword_raise_not_found "keyword"
   ${arcRequireBoundVariables}
   typeset keyword 
   keyword="${1}"
   if _configRaiseObjectNotFound "keywords" "${keyword}.cfg"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function keyword_does_exist {
   # Return true if the keyword exists.
   # >>> keyword_does_exist
   ${arcRequireBoundVariables}
   typeset keyword 
   keyword="${1}"
   if config_does_object_exist "keywords" "${keyword}.cfg"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function keyword_load {
   # Returns the strings to load all keyword configuration files in top down order.
   # >>> eval "$(keyword_load 'keyword')"
   ${arcRequireBoundVariables}
   debug3 "keyword_load: $*"
   typeset keyword 
   keyword="${1}"
   keyword_raise_not_found "${keyword}" && ${returnFalse} 
   echo "$(config_load_all_objects "keywords" "${keyword}.cfg")"
}

function test_keyword_load {
   send_email=0
   eval "$(keyword_load "email")"
   echo "${send_email}" | assert "1"
}

function keywords_count {
   # Return the number of defined keywords.
   # >>> keywords_count
   ${arcRequireBoundVariables}
   keywords_list | num_line_count
}

function test_keywords_count {
   keywords_count | assert ">=7"
}

function keywords_list {
   # Return the list of all keywords.
   # >>> keywords_list [-l|-a]
   # -l: Long list. Include file path to the keyword configuration file.
   # -a: All. List every configuration file for every keyword.
   ${arcRequireBoundVariables}
   config_list_all_objects $* "keywords"
}

function test_keywords_list {
   keywords_list | egrep "critical|warning|log|notify|notice|text|email" | assert -l 7
}
