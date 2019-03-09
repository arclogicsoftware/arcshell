
# module_name="Caching"
# module_about="A simple yet powerful key value data store."
# module_version=1
# module_image="key.png"
# copyright_notice="Copyright 2019 Arclogic Software"

_arcshellCacheDir=${arcTmpDir}/_arcshell_cache
mkdir -p "${_arcshellCacheDir}"

function __exampleCaching {
   # Cache a value for 'city'.
   cache_save "city" "Nashville"
   # Get the value of 'city'.
   x="$(cache_get "city")"
   echo "City is ${x}."
}

function cache_save {
   # Saves a value to cache.
   # >>> cache_save [-stdin] [-term,-t X] [-group,-g "X"] "cache_key" ["cache_value"]
   # -stdin: Use standard input to read the cache value(s). Multiple lines are supported.
   # -term: Number of seconds the value is available for.
   # -group: Cache group. Defaults to 'default'.
   # cache_key: A unique key string used to identify the item within a group.
   # cache_value: Value to cache.
   ${arcRequireBoundVariables}
   debug3 "cache_save: $*"
   typeset expireTime nowTime cacheValue x cacheKey cacheGroup stdin
   expireTime=0
   nowTime=$(dt_epoch)
   cacheKey=
   cacheValue=  
   cacheGroup="default"
   stdin=0
   while (( $# > 0)); do
      case "${1}" in
         "-stdin") stdin=1 ;;
         "-term"|"-t") shift; ((expireTime=nowTime+${1})) ;;
         "-group"|"-g") shift; cacheGroup="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "cache_save" "(( $# <= 2 ))" "$*" && ${returnFalse}
   cacheKey="$(str_to_key_str "${1}")" && shift
   mkdir -p "${_arcshellCacheDir}/${cacheGroup}"
   cacheFile="${_arcshellCacheDir}/${cacheGroup}/${cacheKey}"
   echo "${nowTime} ${expireTime}" > "${cacheFile}"
   if (( ! ${stdin} )); then
      echo "${1:-}" >> "${cacheFile}"
   else
      cat >> "${cacheFile}"
   fi
   chmod 600 "${cacheFile}"
   ${returnTrue} 
}

function test_cache_save {
   cache_save "fooKey" "fooData" && pass_test || fail_test 
   cache_get "fooKey" | assert "fooData" "Returns the value we just cached."
   cache_delete "fooKey" && pass_test || fail_test 
   cache_get -default "X" "fooKey" | assert "X" "Default value is returned because original value has been deleted."
   ls /tmp | cache_save "-stdin" -term 5 "fooKey" && pass_test || fail_test 
   cache_get "fooKey" | wc -l | assert ">3" "Cached values have not expired yet and are more than a few lines long."
   assert_sleep 6
   cache_get -default "X" "fooKey" | assert "X" "Default value is returned because original values have expired."
   cache_delete "fooKey"
}

function cache_get {
   # Gets a value from cache.
   # >>> cache_get [-default,-d "X"] [-group,-g "X"] "cache_key"
   # -default: Returns this default value if item is not in cache.
   ${arcRequireBoundVariables}
   debug3 "cache_get: $*"
   typeset expireTime nowTime cacheValue defaultValue returnVal createdTime cacheKey cacheGroup
   expireTime=0
   nowTime=$(dt_epoch)
   cacheValue=
   defaultValue=
   returnVal=
   cacheKey=
   cacheGroup="default"
   while (( $# > 0)); do
      case $1 in
         "-default"|"-d") shift; defaultValue="${1}" ;;
         "-group"|"-g") shift; cacheGroup="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "cache_get" "(( $# == 1 ))" "$*" && ${returnFalse} 
   cacheKey="$(str_to_key_str "${1}")"
   #mkdir -p "${_arcshellCacheDir}/${cacheGroup}"
   cacheFile="${_arcshellCacheDir}/${cacheGroup}/${cacheKey}"
   if [[ -f "${cacheFile}" ]]; then
      # First line of file contains important times.
      # Replaced the "<<<" format which cause Solaris to complain about unmatched "<<" in ksh.
      IFS=" " read createdTime expireTime < <(head -1 "${cacheFile}" 2> /dev/null)
      [[ -z "${expireTime}" ]] && expireTime=0
      if (( ${expireTime} == 0 || ${expireTime} > ${nowTime} )); then
         cacheValue="$(sed '1d' "${cacheFile}" | tail -1)"
         if [[ -n "${cacheValue:-}" ]]; then
            sed "1d" "${cacheFile}"
         else
            [[ -n "${defaultValue}" ]] && echo "${defaultValue}"
         fi
      else
         [[ -n "${defaultValue}" ]] && echo "${defaultValue}"
      fi
   else
      [[ -n "${defaultValue}" ]] && echo "${defaultValue}"
   fi
   ${returnTrue}
}

function test_cache_get {
   typeset x
   cache_delete "foo"
   x=
   cache_get -default "${x}" "foo" | assert -z "Return null default without error."
   cache_get -default ${x} "foo" 2>&1 | assert_match "ERROR" "Error expected. foo will be consumed as default since x is not quoted."
   cache_get -default '${x}' "foo" | assert_match "x" "Single ticks eliminate variable expansion and literal is expected."
}

function cache_list_keys {
   # List the keys for a set of items in cache.
   # >>> cache_list_keys [-group,-g "X" | cache_group]
   ${arcRequireBoundVariables}
   typeset cacheGroup
   cacheGroup="default"
   while (( $# > 0)); do
      case "${1}" in
         "-group"|"-g") shift; cacheGroup="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "cache_list_keys" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   (( $# == 1 )) && cacheGroup="${1}"
   cacheDir="${_arcshellCacheDir}/${cacheGroup}"
   if [[ -d "${cacheDir}" ]]; then
      ls "${cacheDir}"
   fi
   ${returnTrue}
}

function test_cache_list_keys {
   :
}

function cache_exists {
   # Returns true if a value exists in cache.
   # >>> cache_exists [-group,-g "X"] "cache_key"
   ${arcRequireBoundVariables}
   debug3 "cache_exists: $*"
   typeset cacheKey cacheFile cacheGroup
   cacheKey=
   cacheGroup="default"
   while (( $# > 0)); do
      case $1 in
         "-group"|"-g") shift; cacheGroup="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "cache_exists" "(( $# == 1 ))" "$*" && ${returnFalse} 
   cacheKey="$(str_to_key_str "${1}")"
   cacheFile="${_arcshellCacheDir}/${cacheGroup}/${cacheKey}"
   if [[ -f ${cacheFile} ]]; then
      debug3 "True"
      ${returnTrue} 
   else
      debug3 "False"
      ${returnFalse} 
   fi
}

function test_cache_exists {
   cache_delete "foo"
   ! cache_exists "foo" && pass_test || fail_test 
   cache_save "foo" "x"
   cache_exists "foo" && pass_test || fail_test 
   ! cache_exists -g "bar" "foo" && pass_test || fail_test 
   cache_save -g "bar" "foo" "x"
   cache_exists -g "bar" "foo" && pass_test || fail_test 
   cache_delete "foo"
   cache_delete -g "bar" "foo"
}

function cache_delete {
   # Deletes a cache entry.
   # >>> cache_delete [-group,-g "X"] "cache_key"
   ${arcRequireBoundVariables}
   typeset cacheKey cacheFile cacheGroup
   cacheKey=
   cacheGroup="default"
   while (( $# > 0)); do
      case "${1}" in
         "-group"|"-g") shift; cacheGroup="${1}" ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "cache_delete" "(( $# == 1 ))" "$*" && ${returnFalse} 
   cacheKey="$(str_to_key_str "${1}")"
   cacheFile="${_arcshellCacheDir}/${cacheGroup}/${cacheKey}"
   [[ -f ${cacheFile} ]] && rm ${cacheFile}
   ${returnTrue}
}

function test_cache_delete {
   pass_test
}

function cache_delete_group {
   # Deletes a group of values from cache.
   # >>> cache_delete_group "cache_group"
   ${arcRequireBoundVariables}
   debug3 "cache_delete_group: $*"
   typeset cacheGroup
   utl_raise_invalid_option "cache_delete_group" "(( $# == 1 ))"
   cacheGroup="${1:-}"
   if [[ -d "${_arcshellCacheDir}/${cacheGroup}" ]]; then
      debug3 "** Deleting "${_arcshellCacheDir}/${cacheGroup}""
      rm -rf "${_arcshellCacheDir}/${cacheGroup}"
   fi
   ${returnTrue}
}

function test_cache_delete_group {
   :
}

function test_speed_test {
   typeset x s e t
   x=0
   s=$(dt_epoch)
   echo "Running a speed test, # of seconds to perform 25 saves and gets..."
   while (( ${x} < 25 )); do
      ((x=x+1))
      cache_save "speedTest" "${x}"
      cache_get "speedTest" 1> /dev/null 
   done 
   e=$(dt_epoch)
   ((t=e-s))
   echo "Results: ${t}s"
}

function _cacheThrowError {
   # Error handler for this library.
   # >>> _cacheThrowError "errorText"
  throw_error "arcshell_cache.sh" "${1}"
}

