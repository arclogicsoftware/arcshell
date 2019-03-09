

# module_name="Objects"
# module_about="Manages object styled data structures."
# module_version=1
# module_image="database-2.png"
# copyright_notice="Copyright 2019 Arclogic Software"

dirObjectModels="${arcTmpDir}/_arcshell_models"
mkdir -p "${dirObjectModels}"

dirDeliveredObjects="${arcHome}/config/_objects"
mkdir -p "${dirDeliveredObjects}"

dirGlobalObjects="${arcGlobalHome}/config/_objects"
mkdir -p "${dirGlobalObjects}"

dirUserObjects="${arcUserHome}/config/_objects"
mkdir -p "${dirUserObjects}"

dirTemporaryObjects="${arcTmpDir}/_arcshell_objs"
mkdir -p "${dirTemporaryObjects}"

function objects_register_object_model {
   # Links a function which defines the object model with the model name.
   # >>> objects_register_object_model "modelName" "functionName"
   ${arcRequireBoundVariables}
   debug2 "objects_register_object_model: $*"
   utl_raise_invalid_option "objects_register_object_model" "(( $# == 2 ))" "$*" && ${returnFalse} 
   typeset modelName functionName
   modelName="${1}"
   functionName="${2}"
   str_raise_not_a_key_str "objects_register_object_model" "${modelName}" && ${returnFalse}
   _objectsSaveExistingDef "${modelName}"
   echo "${functionName}" > "${dirObjectModels}/${modelName}.def"
   _objectsCreateObjectInitFile "${modelName}" "${functionName}"
   _objectsDidModelJustChange "${modelName}" $$ objects_update_objects "${modelName}"
}

function _objectsCreateObjectInitFile {
   # Generates the file which is used to init all model values to null.
   # _objectsCreateObjectInitFile "modelName" "functionName"
   ${arcRequireBoundVariables}
   typeset modelName functionName v x
   modelName="${1}"
   functionName="${2}"
   (
   while read x; do
      v="$(echo "${x}" | awk -F"=" '{print $1}')"
      if [[ "${v:0:1}" != "#" ]] && [[ -n "${v}" ]]; then
         echo "${v}=" 
      fi
   done < <(${functionName})
   ) > "${dirObjectModels}/${modelName}"
}

function _objectsDidModelJustChange {
   # Return true if the model changed since the last time it was registered.
   # >>> _objectsDidModelJustChange "modelName"
   ${arcRequireBoundVariables}
   typeset modelName 
   modelName="${1}"
   if [[ -f "${dirObjectModels}/${modelName}.$$" ]]; then
      if (( $(diff "${dirObjectModels}/${modelName}.def" "${dirObjectModels}/${modelName}.$$" | wc -l) )); then
         rm "${dirObjectModels}/${modelName}.$$"
         ${returnTrue}
      else
         rm "${dirObjectModels}/${modelName}.$$"
         ${returnFalse}
      fi
   else
      ${returnFalse}
   fi
}

function _objectsSaveExistingDef {
   # Makes a copy of the existing .def file.
   # >>> _objectsSaveExistingDef "${modelName}"
   ${arcRequireBoundVariables}
   typeset modelName 
   modelName="${1}"
   if [[ -f "${dirObjectModels}/${modelName}.def" ]]; then
      cp "${dirObjectModels}/${modelName}.def" "${dirObjectModels}/${modelName}.$$"
   fi
}

function _objectsReturnObjectFunctionName {
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   if [[ -f "${dirObjectModels}/${modelName}.def" ]]; then
      cat "${dirObjectModels}/${modelName}.def"
   else
      _objectsThrowError "Model does not exist; $*: _objectsReturnObjectFunctionName"
   fi
}

function objects_init_object {
   # Return the text required to set all values associated with a model to null.
   # >>> objects_init_object "modelName"
   ${arcRequireBoundVariables}
   debug2 "objects_init_object: $*"
   modelName="${1}"
   _objectsRaiseModelNotFound "${modelName}" && ${returnFalse}
   echo ". "${dirObjectModels}/${modelName}""
   ${returnTrue}
}

function _objectsRaiseModelNotFound {
   # Throw error and return true if the model is not found. 
   # >>> _objectsRaiseModelNotFound "modelName"
   ${arcRequireBoundVariables}
   typeset modelName 
   modelName="${1}"
   if ! objects_does_object_model_exist "${modelName}"; then
      _objectsThrowError "Model not found: $*: _objectsRaiseModelNotFound"
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function objects_does_object_model_exist {
   # Return true if the model exists
   # >>> objects_does_object_model_exist "modelName"
   ${arcRequireBoundVariables}
   typeset modelName 
   modelName="${1}"
   if [[ -f "${dirObjectModels}/${modelName}.def" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function objects_create_user_object {
   # Create a local object.
   # >>> objects_create_user_object "modelName" "objectName"
   if _objects_create_object "${dirUserObjects}/${1}/${2}"; then
      ${returnTrue}
   else
      ${returnFalse} 
   fi
}

function objects_create_global_object {
   # Create a global object.
   # >>> objects_create_global_object "modelName" "objectName"
   _objects_create_object "${dirGlobalObjects}/${1}/${2}"
}

function objects_create_delivered_object {
   # Create a delivered object.
   # >>> objects_create_delivered_object "modelName" "objectName"
   _objects_create_object "${dirDeliveredObjects}/${1}/${2}"
}

function objects_create_temporary_object {
   # Create a temporary object.
   # >>> objects_create_temporary_object "modelName" "objectName"
   ${arcRequireBoundVariables}
   debug2 "objects_create_temporary_object: $*"
   _objects_create_object "${dirTemporaryObjects}/${1}/${2}" || ${returnFalse} 
   ${returnTrue} 
}

function _objects_create_object {
   # Create an object.
   # >>> _objects_create_object "targetFile"
   ${arcRequireBoundVariables}
   debug2 "_objects_create_object: $*" 
   typeset targetFile modelName objectName modelDir
   targetFile="${1}"
   objectName="$(basename "${targetFile}")"
   modelName="$(basename "$(dirname "${targetFile}")")"
   modelDir="$(dirname "${targetFile}")"
   if [[ -f "${dirObjectModels}/${modelName}.def" ]]; then
      mkdir -p "${modelDir}"
      modelDef=$(cat "${dirObjectModels}/${modelName}.def")
      ${modelDef} > "${targetFile}"
      ${returnTrue}
   else
      ${returnFalse} 
   fi
}

function objects_save_object {
   # Save an object.
   # >>> objects_save_object "modelName" "objectName"
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   if [[ -f "${dirUserObjects}/${modelName}/${objectName}" ]]; then
      objects_create_user_object "${modelName}" "${objectName}"
   elif [[ -f "${dirGlobalObjects}/${modelName}/${objectName}" ]]; then
      objects_create_global_object "${modelName}" "${objectName}"
   elif [[ -f "${dirDeliveredObjects}/${modelName}/${objectName}" ]]; then
      objects_create_delivered_object "${modelName}" "${objectName}"
   elif [[ -f "${dirTemporaryObjects}/${modelName}/${objectName}" ]]; then
      objects_create_temporary_object "${modelName}" "${objectName}"
   else
      objects_create_temporary_object "${modelName}" "${objectName}"
      #_objectsThrowError "Object does not exist: $*: objects_save_object"
   fi
}

# function objects_save_delivered_object {
#    :
# }

# function objects_save_global_object {
#    :
# }

# function objects_save_user_object {
#    :
# }

function objects_save_temporary_object {
   # Save a temporary object.
   # >>> objects_save_temporary_object "modelName" "objectName"
   ${arcRequireBoundVariables}
   typeset modelName objectName
   debug2 "objects_save_temporary_object: $*"
   utl_raise_invalid_option "objects_save_temporary_object" "(( $# == 2 ))" "$*" && ${returnFalse} 
   modelName="${1}"
   objectName="${2}"
   objects_create_temporary_object "${modelName}" "${objectName}" || ${returnFalse} 
   ${returnTrue} 
}

function _objectsRaiseObjectNotFound {
   # Throw error and return true if object is not found.
   # >>> _objectsRaiseObjectNotFound "modelName" "objectName"
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   if ! objects_does_object_exist "${modelName}" "${objectName}"; then
      _objectsThrowError "Object not found: $*: _objectsRaiseObjectNotFound"
      ${returnTrue}
   else
      ${returnFalse}
   fi
}
 
function objects_does_object_exist {
   # Return true if an object exists.
   # >>> objects_does_object_exist "modelName" "objectName"
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   if [[ -f "${dirUserObjects}/${modelName}/${objectName}" ]] || \
      [[ -f "${dirGlobalObjects}/${modelName}/${objectName}" ]] || \
      [[ -f "${dirDeliveredObjects}/${modelName}/${objectName}" ]] || \
      [[ -f "${dirTemporaryObjects}/${modelName}/${objectName}" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function objects_does_user_object_exist {
   # Return true if local object of object type exists.
   # >>> objects_does_user_object_exist "objectType" "objectName"
   ${arcRequireBoundVariables}
   typeset objectType objectName 
   objectType="${1}"
   objectName="${2}"
   [[ -f "${dirUserObjects}/${objectType}/${objectName}" ]] && ${returnTrue} || ${returnFalse}
}

function objects_does_global_object_exist {
   # Return true if global object of object type exists.
   # >>> objects_does_global_object_exist "objectType" "objectName"
   ${arcRequireBoundVariables}
   typeset objectType objectName 
   objectType="${1}"
   objectName="${2}"
   [[ -f "${dirGlobalObjects}/${objectType}/${objectName}" ]] && ${returnTrue} || ${returnFalse}
}

function objects_does_delivered_object_exist {
   # Return true if delivered object of object type exists.
   # >>> objects_does_delivered_object_exist "objectType" "objectName"
   ${arcRequireBoundVariables}
   typeset objectType objectName 
   objectType="${1}"
   objectName="${2}"
   [[ -f "${dirDeliveredObjects}/${objectType}/${objectName}" ]] && ${returnTrue} || ${returnFalse}
}

function objects_does_temporary_object_exist {
   # Return true if temporary object of object type exists.
   # >>> objects_does_temporary_object_exist "objectType" "objectName"
   ${arcRequireBoundVariables}
   debug3 "objects_does_temporary_object_exist: $*"
   typeset objectType objectName 
   objectType="${1}"
   objectName="${2}"
   [[ -f "${dirTemporaryObjects}/${objectType}/${objectName}" ]] && ${returnTrue} || ${returnFalse}
}

function objects_list_objects {
   ${arcRequireBoundVariables}
   typeset modelName
   modelName="${1}"
   (
   objects_list_user_objects "${modelName}"
   objects_list_global_objects "${modelName}"
   objects_list_delivered_objects "${modelName}"
   objects_list_temporary_objects "${modelName}"
   ) | sort -u
}

function objects_list_user_objects {
   ${arcRequireBoundVariables}
   typeset modelName
   modelName="${1}"
   _objects_list_objects "${dirUserObjects}/${modelName}"
}

function objects_list_global_objects {
   ${arcRequireBoundVariables}
   typeset modelName
   modelName="${1}"
   _objects_list_objects "${dirGlobalObjects}/${modelName}"
}

function objects_list_delivered_objects {
   ${arcRequireBoundVariables}
   typeset modelName
   modelName="${1}"
   _objects_list_objects "${dirDeliveredObjects}/${modelName}"
}

function objects_list_temporary_objects {
   # Return a list of temporary objects.
   # >>> objects_list_temporary_objects "modelName"
   ${arcRequireBoundVariables}
   typeset modelName
   modelName="${1}"
   _objects_list_objects "${dirTemporaryObjects}/${modelName}"
}

function _objects_list_objects {
   ${arcRequireBoundVariables}
   typeset dirPath
   dirPath="${1}"
   if [[ -d "${dirPath}" ]]; then
      ls -1 "${dirPath}"
   fi
}

function objects_edit_object {
   # Edit an object file directory in the defined \${EDITOR}.
   # >>> objects_edit_object "modelName" "objectName"
   ${arcRequireBoundVariables}
   typeset modelName objectName f
   modelName="${1}"
   objectName="${2}"
   _objectsRaiseObjectNotFound "${modelName}" "${objectName}" && ${returnFalse}
   if [[ -f "${dirUserObjects}/${modelName}/${objectName}" ]]; then
      f="${dirUserObjects}/${modelName}/${objectName}"
   elif [[ -f "${dirGlobalObjects}/${modelName}/${objectName}" ]]; then
      f="${dirGlobalObjects}/${modelName}/${objectName}"
   elif [[ -f "${dirDeliveredObjects}/${modelName}/${objectName}" ]]; then
      f="${dirDeliveredObjects}/${modelName}/${objectName}"
   elif [[ -f "${dirTemporaryObjects}/${modelName}/${objectName}" ]]; then
      f="${dirTemporaryObjects}/${modelName}/${objectName}"
   fi
   "${arcEditor:-vi}" "${f}"
   ${returnTrue}
}

function objects_show_object {
   # Return the contents of the file which defines an object.
   # >>> objects_show_object "modelName" "objectName"
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   _objectsRaiseObjectNotFound "${modelName}" "${objectName}" && ${returnFalse}
   if [[ -f "${dirUserObjects}/${modelName}/${objectName}" ]]; then
      cat "${dirUserObjects}/${modelName}/${objectName}"
   elif [[ -f "${dirGlobalObjects}/${modelName}/${objectName}" ]]; then
      cat "${dirGlobalObjects}/${modelName}/${objectName}"
   elif [[ -f "${dirDeliveredObjects}/${modelName}/${objectName}" ]]; then
      cat "${dirDeliveredObjects}/${modelName}/${objectName}"
   elif [[ -f "${dirTemporaryObjects}/${modelName}/${objectName}" ]]; then
      cat "${dirTemporaryObjects}/${modelName}/${objectName}"
   else
      _objectsThrowError "Object does not exist: $*: objects_show_object"
   fi
}

function objects_load_object {
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   _objectsRaiseObjectNotFound "${modelName}" "${objectName}" && ${returnFalse}
   echo "$(objects_init_object "${modelName}")"
   if [[ -f "${dirUserObjects}/${modelName}/${objectName}" ]]; then
      echo ". "${dirUserObjects}/${modelName}/${objectName}""
   elif [[ -f "${dirGlobalObjects}/${modelName}/${objectName}" ]]; then
      echo ". "${dirGlobalObjects}/${modelName}/${objectName}""
   elif [[ -f "${dirDeliveredObjects}/${modelName}/${objectName}" ]]; then
      echo ". "${dirDeliveredObjects}/${modelName}/${objectName}""
   elif [[ -f "${dirTemporaryObjects}/${modelName}/${objectName}" ]]; then
      echo ". "${dirTemporaryObjects}/${modelName}/${objectName}""
   else
      _objectsThrowError "Object does not exist: $*: objects_load_object"
   fi
}

function _objectsLoadObject {
   #
   # >>> _objectsLoadObject "file_name"
   ${arcRequireBoundVariables}
   debug2 "_objectsLoadObject: $*"
   typeset file_name
   file_name="${1}"
   if [[ -f "${file_name}" ]]; then
      echo ". "${file_name}""
   else
      _objectsThrowError "Object does not exist: $*: _objectsLoadObject"
   fi
}

function objects_load_delivered_object {
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   _objectsLoadObject "${dirDeliveredObjects}/${modelName}/${objectName}"
}

function objects_load_global_object {
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   _objectsLoadObject "${dirGlobalObjects}/${modelName}/${objectName}"
}

function objects_load_user_object {
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   _objectsLoadObject "${dirUserObjects}/${modelName}/${objectName}"
}

function objects_load_temporary_object {
   # Return the string required to source in a temporary object file.
   # >>> objects_load_temporary_object "modelName" "objectName"
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   _objectsLoadObject "${dirTemporaryObjects}/${modelName}/${objectName}"
}

function objects_delete_object_model {
   # Deletes the object model and all related object instances.
   # >>> objects_delete_object_model "modelName"
   ${arcRequireBoundVariables}
   typeset modelName forceIgnoreExistenceOfModel
   forceIgnoreExistenceOfModel=0
   while (( $# > 0)); do
      case "${1}" in
         "-f") forceIgnoreExistenceOfModel=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "objects_delete_object_model" "(( $# == 1 ))" "$*" && ${returnFalse} 
   modelName="${1}"
   if (( ! ${forceIgnoreExistenceOfModel} )); then
      _objectsRaiseModelNotFound "${modelName}" && ${returnFalse}
   fi
   rm "${dirObjectModels}/${modelName}.def" "${dirObjectModels}/${modelName}" 2> /dev/null
   rm -rf "${dirDeliveredObjects}/${modelName}" 2> /dev/null
   rm -rf "${dirGlobalObjects}/${modelName}" 2> /dev/null
   rm -rf "${dirUserObjects}/${modelName}" 2> /dev/null
   rm -rf "${dirTemporaryObjects}/${modelName}" 2> /dev/null
   ${returnTrue}
}

function objects_delete_object {
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   objects_delete_delivered_object "${modelName}" "${objectName}"
   objects_delete_global_object "${modelName}" "${objectName}"
   objects_delete_user_object "${modelName}" "${objectName}"
   objects_delete_temporary_object "${modelName}" "${objectName}"
   ${returnTrue} 
}

function objects_delete_user_object {
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   if $(objects_does_user_object_exist "${modelName}" "${objectName}"); then
      rm "${dirUserObjects}/${modelName}/${objectName}"
   fi
   ${returnTrue} 
}

function objects_delete_global_object {
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   if $(objects_does_global_object_exist "${modelName}" "${objectName}"); then
      rm "${dirGlobalObjects}/${modelName}/${objectName}"
   fi
   ${returnTrue} 
}

function objects_delete_delivered_object {
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   if $(objects_does_delivered_object_exist "${modelName}" "${objectName}"); then
      rm "${dirDeliveredObjects}/${modelName}/${objectName}"
   fi
   ${returnTrue} 
}

function objects_delete_temporary_object {
   # Delete a temporary object by removing the file that contains the object details.
   # >>> objects_delete_temporary_object "modelName" "objectName"
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   if objects_does_temporary_object_exist "${modelName}" "${objectName}"; then
      rm "${dirTemporaryObjects}/${modelName}/${objectName}"
   fi
   ${returnTrue} 
}

function objects_update_objects {
   # Rebuilds all instances of a model using the current definition.
   # >>> objects_update_objects "modelName"
   ${arcRequireBoundVariables}
   typeset modelName
   modelName="${1}"
   _objectsRaiseModelNotFound "${modelName}" && ${returnFalse}
   debug0 "Updating all instances of object model \"${modelName}\"."
   objects_update_delivered_objects "${modelName}"
   objects_update_global_objects "${modelName}"
   objects_update_user_objects "${modelName}"
   ${returnTrue}
}

function objects_update_delivered_objects {
   #
   ${arcRequireBoundVariables}
   typeset modelName x defFunction
   modelName="${1}"
   while read x; do
      eval "$(objects_load_delivered_object "${modelName}" "${x}")"
      objects_create_delivered_object "${modelName}" "${x}"
   done < <(objects_list_delivered_objects "${modelName}")
}

function objects_update_global_objects {
   #
   ${arcRequireBoundVariables}
   typeset modelName x defFunction
   modelName="${1}"
   while read x; do
      eval "$(objects_load_global_object "${modelName}" "${x}")"
      objects_create_global_object "${modelName}" "${x}"
   done < <(objects_list_global_objects "${modelName}")
}

function objects_update_user_objects {
   #
   ${arcRequireBoundVariables}
   typeset modelName x defFunction
   modelName="${1}"
   while read x; do
      eval "$(objects_load_user_object "${modelName}" "${x}")"
      objects_create_user_object "${modelName}" "${x}"
   done < <(objects_list_user_objects "${modelName}")
}

function objects_list_objects_pretty {
   # Return a formated list of the system objects.
   ${arcRequireBoundVariables}
   typeset modelName objectName deliveredExists globalExists localExists
   deliveredExists="-"
   globalExists="-"
   localExists="-"
   echo "** Objects **"
   while read modelName; do
      str_to_table -o -t -c "15,10,10,10" "Name (Type)" "Delivered" "Global" "User"
      while read objectName; do
         $(objects_does_delivered_system_object_exist "${modelName}" "${objectName}") && deliveredExists="y"
         $(objects_does_global_system_object_exist "${modelName}" "${objectName}") && globalExists="y"
         $(objects_does_local_system_object_exist "${modelName}" "${objectName}") && localExists="y"
         str_to_table -o -c "15,10,10,10" "${objectName} (${modelName})" "${deliveredExists}" "${globalExists}" "${localExists}"
      done < <(objects_list_objects "${modelName}")
   done < <(objects_list_object_models)
}

function objects_list_object_models {
   # Return a list of the available system object types.
   # >>> objects_list_object_models
   ${arcRequireBoundVariables}
   find "${dirObjectModels}" -type f -name "*.def" -exec basename {} \; | sed 's/\.def//'
}

function _objectsThrowError {
   # Error handle for this library.
   # >>> _objectsThrowError "errorText"
   throw_error "arcshell_obj.sh" "${1}"
}

