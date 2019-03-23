
# module_name="Keywords"
# module_about="Manages keywords and their attributes."
# module_version=1
# module_image="sign-1.png"
# copyright_notice="Copyright 2019 Arclogic Software"

mkdir -p "${arcHome}/config/keywords"

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
   # Loads a group into the current shell.
   # >>> eval "$(keyword_load 'keyword')"
   ${arcRequireBoundVariables}
   debug3 "keyword_load: $*"
   typeset keyword 
   keyword="${1}"
   keyword_raise_not_found "${keyword}" && ${returnFalse} 
   echo "$(config_load_object "keywords" "${keyword}.cfg")"
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
