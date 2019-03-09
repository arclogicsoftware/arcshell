
function persons_data_model_for_unittest {
   cat <<EOF
name="${name:-}"
birthdate=${birthdate:-19000101}
EOF
}

function test_objects_setup {
   objects_delete_object_model -f "persons"
}

function test__objectsCreateObjectInitFile {
   :
}

function test__objectsDidModelJustChange {
   :
}

function test__objectsSaveExistingDef {
   :
}

function test_objects_register_object_model {
   ! objects_does_object_model_exist "persons" && pass_test || fail_test "model should not exist"
   objects_register_object_model "persons" "persons_data_model_for_unittest"
   objects_does_object_model_exist "persons" && pass_test || fail_test "model should exist"
   objects_register_object_model "persons" "persons_data_model_for_unittest" 2>&1 | assert -l 0 "Registering an existing model should not return any output."
}

function test__objectsReturnObjectFunctionName {
   _objectsReturnObjectFunctionName "persons" | assert "persons_data_model_for_unittest"
   persons_data_model_for_unittest | grep "name" | assert -l 1
}

function test_objects_init_object {
   name="foo"
   eval "$(objects_init_object "persons")"
   [[ -z "${name}" ]] && pass_test || fail_test "Init call should initialize variable to null."
   (eval "$(objects_init_object "personsX")") 2>&1 | assert_match "ERROR"
}

function test__objectsRaiseModelNotFound {
   :
}

function test_objects_does_object_model_exist {
   objects_does_object_model_exist "persons" && pass_test || fail_test
   ! objects_does_object_model_exist "personsX" && pass_test || fail_test
}

function test_objects_create_user_object {
   objects_delete_object "persons" "l"
   ! $(objects_does_object_exist "persons" "l") && pass_test || fail_test

   name="l"
   birthdate="20000101"
   objects_create_user_object "persons" "l"
   $(objects_does_object_exist "persons" "l") && pass_test || fail_test

   ! $(objects_does_global_object_exist "persons" "l") && pass_test || fail_test

   ! $(objects_does_delivered_object_exist "persons" "l") && pass_test || fail_test
}

function test_objects_create_global_object {
   objects_delete_object "persons" "g"
   ! $(objects_does_object_exist "persons" "g") && pass_test || fail_test

   name="g"
   birthdate="20010101"
   objects_create_global_object "persons" "g"
   $(objects_does_object_exist "persons" "g") && pass_test || fail_test

   ! objects_does_user_object_exist "persons" "g" && pass_test || fail_test

   ! objects_does_delivered_object_exist "persons" "g" && pass_test || fail_test

   ! objects_does_temporary_object_exist "persons" "g" && pass_test || fail_test

   objects_does_global_object_exist "persons" "g" && pass_test || fail_test
}

function test_objects_create_delivered_object {
   objects_delete_object "persons" "d"
   ! objects_does_object_exist "persons" "d" && pass_test || fail_test

   name="d"
   birthdate="20020101"
   objects_create_delivered_object "persons" "d"
   objects_does_object_exist "persons" "d" && pass_test || fail_test

   ! objects_does_user_object_exist "persons" "d" && pass_test || fail_test

   ! objects_does_global_object_exist "persons" "d" && pass_test || fail_test

   ! objects_does_temporary_object_exist "persons" "d" && pass_test || fail_test

   objects_does_delivered_object_exist "persons" "d" && pass_test || fail_test
}

function test_objects_create_temporary_object {
   objects_delete_object "persons" "t"
   ! $(objects_does_object_exist "persons" "t") && pass_test || fail_test
   name="t"
   birthdate="20030101"
   objects_create_temporary_object "persons" "t"
   $(objects_does_object_exist "persons" "t") && pass_test || fail_test
   ! $(objects_does_user_object_exist "persons" "t") && pass_test || fail_test
   ! $(objects_does_global_object_exist "persons" "t") && pass_test || fail_test
   ! $(objects_does_delivered_object_exist "persons" "t") && pass_test || fail_test
   $(objects_does_temporary_object_exist "persons" "t") && pass_test || fail_test
}

function test__objects_create_object {
   pass_test
}

function test_objects_save_object {

   eval "$(objects_load_object "persons" "d")"
   echo "${name}" | assert "d"


   name="Dan"
   objects_save_object "persons" "d"
   name=
   eval "$(objects_load_object "persons" "d")"
   echo "${name}" | assert "Dan"
}

function test_objects_save_temporary_object {

   objects_delete_object "persons" "x"
   ! $(objects_does_temporary_object_exist "persons" "x") && pass_test || fail_test


   name="x"
   objects_save_temporary_object "persons" "x"
   objects_does_temporary_object_exist "persons" "x" && pass_test || fail_test
}

function test__objectsRaiseObjectNotFound {
   :
}

function test_objects_does_object_exist {

   $(objects_does_object_exist "persons" "x") && pass_test || fail_test

   $(objects_does_object_exist "persons" "g") && pass_test || fail_test

   $(objects_does_object_exist "persons" "l") && pass_test || fail_test

   $(objects_does_object_exist "persons" "d") && pass_test || fail_test

   $(objects_does_object_exist "persons" "t") && pass_test || fail_test

   ! $(objects_does_object_exist "persons" "z") && pass_test || fail_test
}

function test_objects_does_user_object_exist {
   :
}

function test_objects_does_global_object_exist {
   :
}

function test_objects_does_delivered_object_exist {
   :
}

function test_objects_does_temporary_object_exist {
   :
}

function test_objects_list_objects {

   objects_list_objects "persons" | assert -l 5
}

function test_objects_list_user_objects {

   objects_list_user_objects "persons" | assert -l 1
}

function test_objects_list_global_objects {

   objects_list_global_objects "persons" | assert -l 1
}

function test_objects_list_delivered_objects {

   objects_list_delivered_objects "persons" | assert -l 1
}

function test_objects_list_temporary_objects {

   objects_list_temporary_objects "persons" | assert -l 2
}

function test__objects_list_objects {
   pass_test
}

function test_objects_edit_object {
   :
}

function test_objects_show_object {
   :
}

function test_objectsLoadObject {

   eval "$(objects_load_object "persons" "t")" 
   echo "${name}" | assert "t"


   eval "$(objects_load_object "persons" "d")" 
   echo "${name}" | assert "Dan"
}

function test_objects_load_temporary_object {
   eval "$(objects_load_temporary_object "persons" "t")" 
   echo "${name}" | assert "t"
}

function test_objects_delete_object_model {
   $(objects_does_object_model_exist "persons") && pass_test || fail_test
   objects_delete_object_model "persons"
   ! $(objects_does_object_model_exist "persons") && pass_test || fail_test
}

function test_objects_delete_object {
   :
}

function test_objects_delete_user_object {
   :
}

function test_objects_delete_global_object {
   :
}

function test_objects_delete_delivered_object {
   :
}

function test_objects_delete_temporary_object {
   :
}

function test_objects_update_objects {
   :
}

function test_objects_list_object_models {
   :
}

