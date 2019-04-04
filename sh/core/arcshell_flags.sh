

# module_name="Flags"
# module_about="Simple way to set and retrieve a keyed value."
# module_version=1
# module_image="flag-4.png"
# copyright_notice="Copyright 2019 Arclogic Software"

_arcshellFlagsDir=${arcTmpDir}/_arcshell_flags
mkdir -p "${_arcshellFlagsDir}"

function __readmeFlags {
   cat <<EOF
> All problems in computer science can be solved with another level of indirection. -- David Wheeler

# Flags

**Simple way to set and retrieve a keyed value.**
EOF
}

function __exampleFlag {
   # Set a flag.
   flag_set "status" "active"
   # Check to see if the flag exists.
   if flag_exists "status"; then
      echo "The 'status' flag exists."
   fi
   # Get the value of a flag.
   if [[ "$(flag_get 'status')" == "active" ]]; then
      flag_set "status" "inactive"
   fi
   # Unset (remove) the flag.
   flag_unset "status"
}

function flag_set {
   # Sets the named flag to the value you specify.
   # >>> flag_set "flag_name" "flag_value"
   ${arcRequireBoundVariables}
   utl_raise_invalid_option "flag_set" "(( $# == 2 ))" "$*" && ${returnFalse} 
   typeset flag_name flag_value
   flag_name="${1}"
   flag_value="${2}"
   echo "${2}" > "${_arcshellFlagsDir}/${flag_name}"
   ${returnTrue} 
}

function flag_get {
   # Returns the value of the flag. If not set returns nothing.
   # >>> flag_get "flag_name"
   ${arcRequireBoundVariables}
   utl_raise_invalid_option "flag_get" "(( $# == 1 ))" "$*" && ${returnFalse} 
   typeset flag_name 
   flag_name="${1}"
   if flag_exists "${flag_name}"; then
      cat "${_arcshellFlagsDir}/${flag_name}"
   fi
   ${returnTrue} 
}

function flag_exists {
   # Returns true if the flag exists.
   # >>> flag_exists "flag_name"
   ${arcRequireBoundVariables}
   utl_raise_invalid_option "flag_exists" "(( $# == 1 ))" "$*" && ${returnFalse} 
   typeset flag_name 
   flag_name="${1}"
   if [[ -f "${_arcshellFlagsDir}/${flag_name}" ]]; then
      ${returnTrue} 
   else 
      ${returnFalse} 
   fi
}

function flag_unset {
   # Unsets the flag.
   # >>> flag_unset "flag_name"
   utl_raise_invalid_option "flag_unset" "(( $# == 1 ))" "$*" && ${returnFalse} 
   ${arcRequireBoundVariables}
   typeset flag_name 
   flag_name="${1}"
   echo "${2}" > "${_arcshellFlagsDir}/${flag_name}"
   ${returnTrue} 
}

