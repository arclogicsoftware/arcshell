
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

function __configArcShellObjects {
   _objectsRegisterConfiguredObjectModels
}

function __readmeArcShellObjects {
   cat <<EOF
# Objects
**Manages object styled data structures.**

Object models are defined using an ArcShell configuration item. You can review existing definitions here. Do not modify any of the delivered items unless you know what you are doing.
\`\`\`
ls "\${arcHome}/config/object_models/"
\`\`\`
Your custom object models belong in the Global or User configuration file locations.

* "\${arcGlobalHome}/config/object_models/"
* "\${arcuUserHome}/config/object_models/"

You can then load, modify, and save records based upon the object models you create using this module.
EOF
}

function __exampleArcShellObjects {
   echo "Returning the contents of the persons.cfg file..."
   cat "${arcHome}/config/object_models/persons.cfg"
   echo ""

   echo "Saving record 'Ethan'..."
   eval "$(objects_init_object "persons")"
   name="Ethan"
   birthdate="19010101"
   objects_save_object "persons" "Ethan"

   echo "Saving record 'Tucker'..."
   eval "$(objects_init_object "persons")"
   name="Tucker"
   objects_save_object "persons" "Tucker"

   echo "Listing all objects or type 'persons'..."
   objects_list_objects "persons"

   echo "Loading 'Ethan' and returning values..."
   eval "$(objects_load_object "persons" "Ethan")"
   echo "${name}:${birthdate}"

   echo "Loading 'Tucker' and returning values..."
   eval "$(objects_load_object "persons" "Tucker")"
   echo "${name}:${birthdate}"

   objects_delete_object "persons" "Ethan"
   objects_delete_object "persons" "Tucker"
}

function _objectsRegisterConfiguredObjectModels {
   ${arcRequireBoundVariables}
   typeset object_model object_model_file object_model_type
   while read object_model; do
      object_model_file="$(config_return_object_path "object_models" "${object_model}")"
      object_model_type="$(file_get_file_root_name "${object_model_file}")"
      objects_register_object_model_file "${object_model_type}" "${object_model_file}"
   done < <(config_list_all_objects "object_models")
}

function objects_register_object_model_file {
   # Registers an object model using a file instead of a function.
   # >>> objects_register_object_model_file "modelName" "filePath"
   ${arcRequireBoundVariables}
   typeset modelName filePath
   modelName="${1}"
   filePath="${2}"
   str_raise_not_a_key_str "objects_register_object_model_file" "${modelName}" && ${returnFalse}
   _objectsSaveExistingDef "${modelName}"
   _objectsReturnLoadableObjectModel "${filePath}" > "${dirObjectModels}/${modelName}.def" || ${returnFalse} 
   cat "${filePath}" | grep "=" | str_remove_comments -stdin | awk -F"=" '{print $1}' | sed "s/$/=/" > "${dirObjectModels}/${modelName}"
   _objectsDidModelJustChange "${modelName}" $$ objects_update_objects "${modelName}"
 }

 function _objectsReturnLoadableObjectModel {
   # Takes "var=val" lines and returns "var=${var:-val}" instead.
   # >>> _objectsReturnLoadableObjectModel "filePath"
   ${arcRequireBoundVariables}
   typeset filePath line_in_file
   filePath="${1}"
   file_raise_file_not_found "${filePath}" && ${returnFalse} 
   echo "cat <<EOF"
   while read line_in_file; do
      if [[ -n "${line_in_file%%=*}" ]]; then
         printf "%s=\"%s%s:-%s%s\"\n" "${line_in_file%%=*}" "\${" "${line_in_file%%=*}" "${line_in_file#*=}" "}"
      fi
   done < <(str_remove_comments "${filePath}")
   echo "EOF"
   echo ""
   ${returnTrue} 
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

function objects_init_object {
   # Return the text required to set all values associated with a model to null.
   # >>> objects_init_object "modelName"
   ${arcRequireBoundVariables}
   debug3 "objects_init_object: $*"
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
   # Create an object.
   # >>> objects_create_user_object "modelName" "objectName"
   if _objCreateObject "${dirUserObjects}/${1}/${2}"; then
      ${returnTrue}
   else
      ${returnFalse} 
   fi
}

function objects_create_global_object {
   # Create an object.
   # >>> objects_create_global_object "modelName" "objectName"
   _objCreateObject "${dirGlobalObjects}/${1}/${2}"
}

function objects_create_delivered_object {
   # Create an object.
   # >>> objects_create_delivered_object "modelName" "objectName"
   _objCreateObject "${dirDeliveredObjects}/${1}/${2}"
}

function objects_create_temporary_object {
   # Create an object.
   # >>> objects_create_temporary_object "modelName" "objectName"
   ${arcRequireBoundVariables}
   debug3 "objects_create_temporary_object: $*"
   _objCreateObject "${dirTemporaryObjects}/${1}/${2}" || ${returnFalse} 
   ${returnTrue} 
}

function _objCreateObject {
   # Create an object.
   # >>> _objCreateObject "targetFile"
   ${arcRequireBoundVariables}
   debug3 "_objCreateObject: $*" 
   typeset targetFile modelName objectName modelDir
   targetFile="${1}"
   objectName="$(basename "${targetFile}")"
   modelName="$(basename "$(dirname "${targetFile}")")"
   modelDir="$(dirname "${targetFile}")"
   if [[ -f "${dirObjectModels}/${modelName}.def" ]]; then
      mkdir -p "${modelDir}"
      . "${dirObjectModels}/${modelName}.def" > "${targetFile}"
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
   # Save an object.
   # >>> objects_save_temporary_object "modelName" "objectName"
   ${arcRequireBoundVariables}
   typeset modelName objectName
   debug3 "objects_save_temporary_object: $*"
   utl_raise_invalid_option "objects_save_temporary_object" "(( $# == 2 ))" "$*" && ${returnFalse} 
   modelName="${1}"
   objectName="${2}"
   if objects_create_temporary_object "${modelName}" "${objectName}"; then
      ${returnTrue} 
   else 
      ${returnFalse} 
   fi
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
   # Return true if object exists.
   # >>> objects_does_object_exist "objectType" "objectName"
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
   # Return true if object exists.
   # >>> objects_does_user_object_exist "objectType" "objectName"
   ${arcRequireBoundVariables}
   typeset objectType objectName 
   objectType="${1}"
   objectName="${2}"
   [[ -f "${dirUserObjects}/${objectType}/${objectName}" ]] && ${returnTrue} || ${returnFalse}
}

function objects_does_global_object_exist {
   # Return true if object exists.
   # >>> objects_does_global_object_exist "objectType" "objectName"
   ${arcRequireBoundVariables}
   typeset objectType objectName 
   objectType="${1}"
   objectName="${2}"
   [[ -f "${dirGlobalObjects}/${objectType}/${objectName}" ]] && ${returnTrue} || ${returnFalse}
}

function objects_does_delivered_object_exist {
   # Return true if object exists.
   # >>> objects_does_delivered_object_exist "objectType" "objectName"
   ${arcRequireBoundVariables}
   typeset objectType objectName 
   objectType="${1}"
   objectName="${2}"
   [[ -f "${dirDeliveredObjects}/${objectType}/${objectName}" ]] && ${returnTrue} || ${returnFalse}
}

function objects_does_temporary_object_exist {
   # Return true if object exists.
   # >>> objects_does_temporary_object_exist "objectType" "objectName"
   ${arcRequireBoundVariables}
   debug3 "objects_does_temporary_object_exist: $*"
   typeset objectType objectName 
   objectType="${1}"
   objectName="${2}"
   [[ -f "${dirTemporaryObjects}/${objectType}/${objectName}" ]] && ${returnTrue} || ${returnFalse}
}

function objects_list_objects {
   # Return a list of objects.
   # >>> objects_list_objects "modelName"
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
   # Return a list of objects.
   # >>> objects_list_user_objects "modelName"
   ${arcRequireBoundVariables}
   typeset modelName
   modelName="${1}"
   _objListObjects "${dirUserObjects}/${modelName}"
}

function objects_list_global_objects {
   # Return a list of objects.
   # >>> objects_list_global_objects "modelName"
   ${arcRequireBoundVariables}
   typeset modelName
   modelName="${1}"
   _objListObjects "${dirGlobalObjects}/${modelName}"
}

function objects_list_delivered_objects {
   # Return a list of objects.
   # >>> objects_list_delivered_objects "modelName"
   ${arcRequireBoundVariables}
   typeset modelName
   modelName="${1}"
   _objListObjects "${dirDeliveredObjects}/${modelName}"
}

function objects_list_temporary_objects {
   # Return a list of objects.
   # >>> objects_list_temporary_objects "modelName"
   ${arcRequireBoundVariables}
   typeset modelName
   modelName="${1}"
   _objListObjects "${dirTemporaryObjects}/${modelName}"
}

function _objListObjects {
   # List the objects in a directory.
   # >>> _objListObjects "dirPath"
   ${arcRequireBoundVariables}
   typeset dirPath
   dirPath="${1}"
   if [[ -d "${dirPath}" ]]; then
      ls -1 "${dirPath}"
   fi
}

function objects_load_object {
   # Return string used to load an object.
   # >>> eval "$(objects_load_object "modelName" "objectName")"
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

function objects_load_delivered_object {
   # Return string used to load an object.
   # >>> eval "$(objects_load_delivered_object "modelName" "objectName")"
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   echo ". \"${dirDeliveredObjects}/${modelName}/${objectName}\""
}

function objects_load_global_object {
   # Return string used to load an object.
   # >>> eval "$(objects_load_global_object "modelName" "objectName")"
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   echo ". \"${dirGlobalObjects}/${modelName}/${objectName}\""
}

function objects_load_user_object {
   # Return string used to load an object.
   # >>> eval "$(objects_load_user_object "modelName" "objectName")"
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   echo ". \"${dirUserObjects}/${modelName}/${objectName}\""
}

function objects_load_temporary_object {
   # Return string used to load an object.
   # >>> eval "$(objects_load_temporary_object "modelName" "objectName")"
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   echo ". \"${dirTemporaryObjects}/${modelName}/${objectName}\""
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
   # Deletes an object.
   # >>> objects_delete_object "modelName" "objectName"
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   if objects_delete_delivered_object "${modelName}" "${objectName}" || \
      objects_delete_global_object "${modelName}" "${objectName}" || \
      objects_delete_user_object "${modelName}" "${objectName}" || \
      objects_delete_temporary_object "${modelName}" "${objectName}"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function objects_delete_user_object {
    # Deletes an object.
   # >>> objects_delete_user_object "modelName" "objectName"
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   if $(objects_does_user_object_exist "${modelName}" "${objectName}"); then
      rm "${dirUserObjects}/${modelName}/${objectName}"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function objects_delete_global_object {
    # Deletes an object.
   # >>> objects_delete_global_object "modelName" "objectName"
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   if $(objects_does_global_object_exist "${modelName}" "${objectName}"); then
      rm "${dirGlobalObjects}/${modelName}/${objectName}"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function objects_delete_delivered_object {
    # Deletes an object.
   # >>> objects_delete_delivered_object "modelName" "objectName"
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   if $(objects_does_delivered_object_exist "${modelName}" "${objectName}"); then
      rm "${dirDeliveredObjects}/${modelName}/${objectName}"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function objects_delete_temporary_object {
    # Deletes an object.
   # >>> objects_delete_temporary_object "modelName" "objectName"
   ${arcRequireBoundVariables}
   typeset modelName objectName
   modelName="${1}"
   objectName="${2}"
   if objects_does_temporary_object_exist "${modelName}" "${objectName}"; then
      rm "${dirTemporaryObjects}/${modelName}/${objectName}"
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function objects_update_objects {
   # Rebuilds all instances of a model using the current definition.
   # >>> objects_update_objects "modelName"
   ${arcRequireBoundVariables}
   typeset modelName
   modelName="${1}"
   _objectsRaiseModelNotFound "${modelName}" && ${returnFalse}
   debug0 "Updating all instances of object model \"${modelName}\"."
   _objRebuildDeliveredObjects "${modelName}"
   _objRebuildGlobalObjects "${modelName}"
   _objRebuildUserObjects "${modelName}"
   ${returnTrue}
}

function _objRebuildDeliveredObjects {
   # Rebuilds the objects using the current model.
   # >>> _objRebuildDeliveredObjects "modelName"
   ${arcRequireBoundVariables}
   typeset modelName x defFunction
   modelName="${1}"
   while read x; do
      eval "$(objects_load_delivered_object "${modelName}" "${x}")"
      objects_create_delivered_object "${modelName}" "${x}"
   done < <(objects_list_delivered_objects "${modelName}")
}

function _objRebuildGlobalObjects {
   # Rebuilds the objects using the current model.
   # >>> _objRebuildGlobalObjects "modelName"
   ${arcRequireBoundVariables}
   typeset modelName x defFunction
   modelName="${1}"
   while read x; do
      eval "$(objects_load_global_object "${modelName}" "${x}")"
      objects_create_global_object "${modelName}" "${x}"
   done < <(objects_list_global_objects "${modelName}")
}

function _objRebuildUserObjects {
   # Rebuilds the objects using the current model.
   # >>> _objRebuildUserObjects "modelName"
   ${arcRequireBoundVariables}
   typeset modelName x 
   modelName="${1}"
   while read x; do
      eval "$(objects_load_user_object "${modelName}" "${x}")"
      objects_create_user_object "${modelName}" "${x}"
   done < <(objects_list_user_objects "${modelName}")
}

function _objectsThrowError {
   # Error handle for this library.
   # >>> _objectsThrowError "errorText"
   throw_error "arcshell_obj.sh" "${1}"
}

