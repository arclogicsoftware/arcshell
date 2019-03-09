function test_menu_setup_testing {
   __setupArcShellMenu
}

function test_create_foo_menu {
   menu_create "foo" "Foo Menu"
   menu_add_text "Vanilla"
   menu_add_text "Chocolate"
   menu_add_text "Strawberry"
}

function test_menu_create {
   menu_create "not a key" "foo" 2>&1 | assert_match "ERROR"
   menu_create "bar" "Bar Menu"
   test_create_foo_menu
   menu_show -select "q" | egrep "Vanilla|Chocolate|Strawberry" | assert -l 3 
   menu_create "foo" "Please select a flavor."
   menu_add_text "Vanilla"
   menu_add_text "Chocolate"
   menu_show -select "q" | egrep "Please select a flavor." | assert -l 1 "Menu title is incorrect."
   menu_delete "foo"
}

function test_menu_set {
   menu_set "X" 2>&1 | assert_match "ERROR"
   menu_set "bar" 
   echo "${_g_workingMenuKey}" | assert "bar"
   debug2 "_g_workingMenuKey=${_g_workingMenuKey}: test_menu_set"
}

function test_menu_set_all_option_on {
   debug2 "_g_workingMenuKey=${_g_workingMenuKey}: test_menu_set_all_option_on"
   eval "$(_menuLoad "${_g_workingMenuKey}")"
   echo ${MenuEnableAllOption} | assert 0
   menu_set_all_option_on
   eval "$(_menuLoad "${_g_workingMenuKey}")"
   echo ${MenuEnableAllOption} | assert 1
}

function test_menu_set_all_option_off {
   eval "$(_menuLoad "${_g_workingMenuKey}")"
   echo ${MenuEnableAllOption} | assert 1
   menu_set_all_option_off
   eval "$(_menuLoad "${_g_workingMenuKey}")"
   echo ${MenuEnableAllOption} | assert 0
}

function test_menu_set_all_option_to_default {
   test_create_foo_menu
   eval "$(_menuLoad "${_g_workingMenuKey}")"
   echo ${MenuAllOptionIsDefault} | assert 0
   menu_set_all_option_to_default
   eval "$(_menuLoad "${_g_workingMenuKey}")"
   echo ${MenuEnableAllOption} | assert 1
   echo ${MenuAllOptionIsDefault} | assert 1
   menu_show -select "q" | egrep "\[4\]|\[ 4 \]" | assert -l 2
}

function test_menu_add_text {
   menu_add_text "North"
}

function test_menu_add_menu {
   menu_add_menu "bar" "Link To Self"
}

function test_menu_add_menu {
   menu_add_command "uptime" "Run uptime"
}

function test_menu_delete {
   menu_delete 
   _menuRaiseWorkingMenuNotSet 2>&1 | assert_match "ERROR"
}

function test__menuPrintMenuItems {
   test_create_foo_menu
   _menuPrintMenuItems "foo" | assert -l 3
}

function test__menuDeleteMenu {
   menu_does_menu_exist "foo" && pass_test || fail_test
   _menuDeleteMenu "foo"
   ! menu_does_menu_exist "foo" && pass_test || fail_test
}

function test_menu_get_selected_item {
   menu_create "foo" "Menu One"
   menu_add_text "ABC"
   menu_show -select 1 "foo" 1> /dev/null
   menu_get_selected_item "foo" | assert "ABC"
}

function test_menu_list_selected_items {
   menu_create "foo" "Main Menu"
   menu_add_text "LONG"
   menu_add_text "LAT"
   menu_set_all_option_on "foo"
   # This will select the 'All' option.
   #menu_show -select 3 "foo"
   menu_show -select 3 "foo" 1> /dev/null
   menu_list_selected_items "foo" | egrep "LONG|LAT" | assert -l 2
}

function test_menu_list_all_items {
   test_create_foo_menu
   menu_list_all_items "foo" | egrep "Vanilla|Chocolate|Strawberry" | assert -l 3
}

function test_menu_get_selected_item_count {
   menu_show -select 1 "foo" 1> /dev/null
   menu_get_selected_item_count "foo" | assert 1
   menu_show -select 3 "foo" 1> /dev/null
   menu_get_selected_item_count "foo" | assert 1
   menu_show -select "q" "foo" 1> /dev/null
   menu_get_selected_item_count "foo" | assert 0
}

function test_menu_does_menu_exist {
   menu_does_menu_exist "foo" && pass_test || fail_test
   _menuDeleteMenu "foo"
   ! menu_does_menu_exist "foo" && pass_test || fail_test
}

function test__menuLoad {
   menu_create "foo" "Test Menu"
   eval "$(_menuLoad "foo")"
   echo "${MenuTitle}" | assert "Test Menu"
}

function test_unit_test_cleanup {
   _menuDeleteMenu "test"
   _menuDeleteMenu "ArcShellMenu"
   _menuDeleteMenu "foo"
   _menuDeleteMenu "menu2"
}

