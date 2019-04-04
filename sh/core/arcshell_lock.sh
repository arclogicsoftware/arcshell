
# module_name="Locking"
# module_about="Creates and manages locks for you."
# module_version=1
# module_image="lock.png"
# copyright_notice="Copyright 2019 Arclogic Software"

arcLockDir="${arcTmpDir}/_arcshell_locks"
mkdir -p "${arcLockDir}"

function __readmeLocking {
   cat <<EOF
# Locking
**Creates and manages locks for you.**

EOF
}

function __setupArcShellLock {
   :
}

function lock_aquire {
   # Try to aquire the "lock_id" lock.
   # >>> lock_aquire [-try,-t X] [-term,-t X] [-force,-f] [-error,-e] "lock_id"
   # -try: Number of attempts to try to aquire a lock before failing. 1 second between attempts.
   # -term: Number of seconds lock is held for before auto expiring.
   # -force: Throw error and force aquisition of the lock after waiting if need be.
   # -error: Throw error if you fail to aquire the lock.
   # lock_id: A unique string to identify the lock.
   ${arcRequireBoundVariables}
   typeset unixEpoch expireEpoch lockTerm tryCount checkCount lockAquired forceLock lock_id throwError 
   debug3 "lock_aquire: $*"
   unixEpoch=$(dt_epoch)
   expireEpoch=
   lockTerm=0
   tryCount=1
   forceLock=0
   throwError=0
   while (( $# > 0)); do
      case ${1} in
         "-try"|"-t")     
            shift
            tryCount=${1}
            ;;
         "-term"|"-t")
            shift
            lockTerm=${1}
            ;;
         "-force"|"-f")
            forceLock=1
            ;;
         "-error"|"-e")
            throwError=1 
            ;;
         *) 
            break                                    
            ;;
      esac
      shift
   done
   utl_raise_invalid_option "lock_aquire" "(( $# == 1 ))" "$*" && ${returnFalse} 
   lock_id="$(str_to_key_str "${1}")"
   if _lockDoesExist "${lock_id}"; then
      _lockRemoveIfExpired "${lock_id}"
      _lockRemoveIfStale "${lock_id}"
   fi
   checkCount=0
   lockAquired=0
   while (( ${checkCount} < ${tryCount} )); do
      if _lockTryToAquireLock "${lock_id}"; then
         lockAquired=1
         if (( ${lockTerm} > 0 )); then
            ((expireEpoch=unixEpoch+lockTerm))
            cache_save "lock-${lock_id}" "${expireEpoch}"
         fi
         break
      fi
      sleep 1
      _lockRemoveIfExpired "${lock_id}"
      _lockRemoveIfStale "${lock_id}"
      ((checkCount=checkCount+1))
   done
   if (( ! ${lockAquired} && ${forceLock} )); then
      lock_release "${lock_id}"
      _lockAquire "${lock_id}"
      if _lockIsMyLock "${lock_id}"; then
         log_error -2 -logkey "locks" "'${lock_id}' was taken by force."
         lockAquired=1
      else 
         log_error -2 -logkey "lock" -tags "${lock_id}" "Unable to force aquire lock."
      fi
   fi
   if (( ${lockAquired} )); then
      ${returnTrue} 
   else
      if (( ${throwError} )); then
         log_error -2 -logkey "locks" "Failed to aquire lock '${lock_id}'."
      fi
      ${returnFalse} 
   fi
}

function test__lockAquire {
   lock_release "foo"
   lock_aquire "foo" && pass_test || fail_test
   ! lock_aquire "foo" && pass_test || fail_test
   lock_release "foo"
}

function lock_release {
   # Remove "lock_id" if it exists. No errors if it does not exist.
   # >>> lock_release "lock_id"
   ${arcRequireBoundVariables}
   typeset lock_id
   lock_id="$(str_to_key_str "${1}")"
   debug3 "lock_release: $*"
   find "${arcLockDir}" -type f -name "${lock_id}" -exec rm {} \;
}

function test_lock_release {
   lock_release "foo"
   lock_aquire "foo" && pass_test || fail_test
   ! lock_aquire "foo" && pass_test || fail_test
   lock_release "foo"
   lock_aquire "foo" && pass_test || fail_test
}

function _lockGetPid {
   # Return the process ID which created the "lock_id" lock.
   # >>> _lockGetPid "lock_id"
   ${arcRequireBoundVariables}
   typeset lock_id lockFile
   lock_id="${1}"
   lockFile="${arcLockDir}/${lock_id}"
   if _lockDoesExist "${lock_id}"; then
      cat "${lockFile}"
   else
      echo "0000000000"
   fi
}

function test__lockGetPid {
   lock_release "foo"
   _lockGetPid "foo" | assert "0000000000"
   lock_aquire "foo" 
   _lockGetPid "foo" | egrep -v "0000000000" | assert ">0"
   lock_release "foo"
}

function _lockIsLocked {
   # Return true if "lock_id" exists, is not expired and is not stale.
   # Note: Locks are automatically removed if found to be expired or stale.
   # >>> _lockIsLocked "lock_id"
   ${arcRequireBoundVariables}
   typeset lock_id 
   lock_id="${1}"
   ! _lockDoesExist "${lock_id}" && ${returnFalse}
   if _lockIsExpired "${lock_id}" || _lockIsStale "${lock_id}"; then
      lock_release "${lock_id}"
      ${returnFalse}
   fi
   ${returnTrue}
}

function test__lockIsLocked {
   lock_release "foo"
   lock_aquire "foo"
   _lockIsLocked "foo" && pass_test || fail_test
   lock_release "foo"
   lock_aquire -term 1 "foo"
   sleep 2
   ! _lockIsLocked "foo" && pass_test || fail_test
}

function _lockDoesExist {
   # Return true if "lock_id" exists.
   # >>> _lockDoesExist "lock_id"
   ${arcRequireBoundVariables}
   typeset lock_id lockFile
   lock_id="${1}" 
   lockFile="${arcLockDir}/${lock_id}"
   if file_exists "${lockFile}"; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test__lockDoesExist {
   lock_release "foo"
   lock_aquire "foo" && pass_test || fail_test
   _lockDoesExist "foo" && pass_test || fail_test
   lock_release "foo"
   lock_aquire -term 5 "foo" && pass_test || fail_test
   _lockDoesExist "foo" && pass_test || fail_test
   sleep 6
   # Should still exist, although it would not be locked.
   _lockDoesExist "foo" && pass_test || fail_test
   ! _lockIsLocked "foo" && pass_test || fail_test
   lock_release "foo"
}

function _lockCreateLockFile {
   # Creates the lock file for "lock_id" and stores the current process ID in it.
   # >>> _lockCreateLockFile "lock_id"
   ${arcRequireBoundVariables}
   typeset lock_id lockFile
   lock_id="${1}"
   lockFile="${arcLockDir}/${lock_id}"
   debug3 "_lockCreateLockFile: $*"
   echo $$ > "${lockFile}"
}

function test__lockCreateLockFile {
   _lockCreateLockFile "foo" 
   _lockGetPid "foo" | assert $$ 
   file_exists "${arcLockDir}/foo" && pass_test || fail_test
   rm "${arcLockDir}/foo"
}

function _lockIsMyLock {
   # Return true if the process ID associated with "lock_id" is the current process ID.
   # >>> _lockIsMyLock "lock_id"
   ${arcRequireBoundVariables}
   typeset lock_id 
   lock_id="${1}" 
   if (( $(_lockGetPid "${lock_id}") == $$ )); then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test__lockIsMyLock {
   lock_aquire "foo" && pass_test || fail_test
   _lockIsMyLock "foo" && pass_test || fail_test
   lock_release "foo"
   ! _lockIsMyLock "foo" && pass_test || fail_test
}

function _lockIsLockOwnersPidRunning {
   # Return true if the process ID associated with "lock_id" is running.
   # >>> _lockIsLockOwnersPidRunning "lock_id"
   ${arcRequireBoundVariables}
   debug3 "_lockIsLockOwnersPidRunning: $*"
   typeset lock_id lockPid
   lock_id="${1}" 
   lockPid=$(_lockGetPid "${lock_id}")
   if num_is_gt_zero $(ps -ef | grep "${lockPid}" | grep -v "grep" | wc -l); then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test__lockIsLockOwnersPidRunning {
   lock_release "foo"
   lock_aquire "foo"
   _lockIsLockOwnersPidRunning "foo" && pass_test || fail_test
   lock_release "foo"
   lock_aquire "foo"
   echo "999999999" > "${arcLockDir}/foo"
   ! _lockIsLockOwnersPidRunning "foo" && pass_test || fail_test
   lock_release "foo"
}

function _lockAquire {
   # Return true if we are able to create the lock file then verify we are the owner.
   # >>> _lockAquire "lock_id"
   ${arcRequireBoundVariables}
   typeset lock_id
   lock_id="${1}"
   _lockCreateLockFile "${lock_id}"
   sleep 1
   if _lockIsMyLock "${lock_id}"; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test__lockAquire {
   lock_release "foo"
   _lockAquire "foo" && pass_test || fail_test
   _lockAquire "foo" && pass_test || fail_test
   lock_release "foo"
}

function _lockIsStale {
   # Return true if the process ID which owns a lock is not running.
   # >>> _lockIsStale "lock_id"
   ${arcRequireBoundVariables}
   typeset lock_id
   lock_id="${1}"
   if _lockIsLockOwnersPidRunning "${lock_id}"; then
      ${returnFalse}
   else
      ${returnTrue}
   fi
}

function test__lockIsStale {
   lock_release "foo"
   lock_aquire "foo"
   ! _lockIsStale "foo" && pass_test || fail_test
   echo "999999999" > "${arcLockDir}/foo"
   _lockIsStale "foo" && pass_test || fail_test
}

function _lockTryToAquireLock {
   # Return true if the attempt to aquire "lock_id" is successfull.
   # >>> _lockTryToAquireLock "lock_id"
   ${arcRequireBoundVariables}
   typeset lock_id
   lock_id="${1}"
   if ! _lockIsLocked "${lock_id}"; then
      _lockAquire "${lock_id}" && ${returnTrue}
   fi
   debug3 "_lockTryToAquireLock: $*: no"
   ${returnFalse}
}

function test__lockTryToAquireLock {
   lock_release "foo"
   lock_aquire "foo"
   ! _lockTryToAquireLock "foo" && pass_test || fail_test
   lock_release "foo"
   _lockTryToAquireLock "foo" && pass_test || fail_test
   lock_release "foo"
}

function _lockIsExpired {
   # Return true if "lock_id" has expired.
   # >>> _lockIsExpired "lock_id"
   ${arcRequireBoundVariables}
   typeset lock_id unixEpoch expireEpoch
   lock_id="${1}"
   unixEpoch=$(dt_epoch)
   expireEpoch=$(cache_get "lock-${lock_id}")
   if is_defined "${expireEpoch}"; then
      if (( ${unixEpoch} >= ${expireEpoch} )); then
         cache_delete "lock-${lock_id}"
         ${returnTrue}
      else
         ${returnFalse}
      fi
   else
      ${returnFalse}
   fi
}

function test__lockIsExpired {
   lock_release "foo"
   lock_aquire -term 5 "foo" && pass_test || fail_test
   ! lock_aquire "foo" && pass_test || fail_test
   sleep 6
   lock_aquire "foo" && pass_test || fail_test
}

function _lockRemoveIfExpired {
   # Checks "lock_id" to see if it needs to be automatically removed.
   # >>> _lockRemoveIfExpired "lock_id"
   ${arcRequireBoundVariables}
   typeset lock_id
   lock_id="${1}"
   if _lockIsExpired "${lock_id}"; then
      debug3 "_lockRemoveIfExpired: $*"
      lock_release "${lock_id}"
   fi
}

function test__lockRemoveIfExpired {
   :
}

function _lockRemoveIfStale {
   # Checks "lock_id" to see if it needs to be automatically removed.
   # >>> _lockRemoveIfStale "lock_id"
   ${arcRequireBoundVariables}
   typeset lock_id
   lock_id="${1}"
   if _lockIsStale "${lock_id}"; then
      debug3 "_lockRemoveIfStale: $*: stale"
      lock_release "${lock_id}"
   fi
}

function test__lockRemoveIfStale {
   :
}

