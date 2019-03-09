function test_stack_create {
   stack_delete "foo"
   ! $(stack_exists "foo") && pass_test || fail_test
   stack_create "foo"
   $(stack_exists "foo") && pass_test || fail_test
}

function test_stack_add {
   stack_add "foo" "bar"
   stack_return_last_value "foo" | assert "bar"
}

function test_stack_list {
   :
}

function test_stack_delete {
   pass_test
}

function test_stack_copy {
   :
}

function test__stack_auto_create_stack {
   :
}

function test_stack_return_last_value {
   pass_test
}

function test_stack_remove_last_value {
   stack_add "foo" "bin"
   stack_return_last_value "foo" | assert "bin"
   stack_remove_last_value "foo"
   stack_return_last_value "foo" | assert "bar"
}

function test_stack_remove_first_value {
   :
}

function test_stack_pop_last_value {
   stack_pop_last_value "foo" | assert "bar"
   stack_count "foo" | assert 0
}

function test_stack_pop_first_value {
   :
}

function test_stack_count {
   pass_test
}

function test_stack_has_values {
   stack_clear "foo"
   ! $(stack_has_values "foo") && pass_test || fail_test 
   stack_add "foo" "bar"
   $(stack_has_values "foo") && pass_test || fail_test 
}

function test_stack_exists {
   $(stack_exists "foo") && pass_test || fail_test 
   stack_delete "foo"
   ! $(stack_exists "foo") && pass_test || fail_test 
}

function test_stack_clear {
   pass_test
}

function test_stack_value_count {
   :
}

