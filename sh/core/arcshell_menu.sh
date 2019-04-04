

# module_name="Menus"
# module_about="Builds rich command line menu systems that are dynamic."
# module_version=1
# module_image="menu-3.png"
# copyright_notice="Copyright 2019 Arclogic Software"

_menuDir="${arcTmpDir}/_arcshell_menus"
mkdir -p "${_menuDir}"
_tty=$(boot_return_tty_device)
_g_workingMenuKey=

function _menuItemObjectModule {
   cat <<EOF
MenuItemText="${MenuItemText:-}"
MenuItemValue="${MenuItemValue:-}"
MenuItemIsSubmenu=${MenuItemIsSubmenu:-}
MenuItemIsCommand=${MenuItemIsCommand:-}
EOF
}

function menu_create {
   # Create or recreate a menu and sets the 'working' menu.
   # >>> menu_create "key" "title"
   # key: Key string used to reference the menu.
   # title: Title string.
   ${arcRequireBoundVariables}
   typeset title key
   utl_raise_invalid_option "menu_create" "(( $# == 2 ))" "$*" && ${returnFalse} 
   key="${1}"
   title="${2}"
   str_raise_not_a_key_str "menu_create" "${key}" && ${returnFalse}
   rm -rf "${_menuDir}/${key}"
   mkdir -p "${_menuDir}/${key}"
   eval "$(objects_init_object "arcshell_menu")"
   MenuTitle="${title}"
   cp /dev/null ${_menuDir}/${key}/itemCount
   objects_save_temporary_object "arcshell_menu" "${key}" 
   menu_set "${key}"
   ${returnTrue}
}

function menu_set {
   # Sets the current working menu.
   # >>> menu_set "key"
   ${arcRequireBoundVariables}
   typeset key 
   key="${1}"
   _menuRaiseMenuNotFound "${key}" && ${returnFalse}
   _g_workingMenuKey="${key}"
   debug3 "_g_workingMenuKey=${_g_workingMenuKey}: menu_set"
   ${returnTrue}
}

function menu_set_all_option_on {
   # Enables the 'All' option for the current working menu.
   # >>> menu_set_all_option_on 
   ${arcRequireBoundVariables}
   _menuRaiseWorkingMenuNotSet && ${returnFalse}
   eval "$(_menuLoad "${_g_workingMenuKey}")"
   MenuEnableAllOption=1
   objects_save_temporary_object "arcshell_menu" "${_g_workingMenuKey}"
   ${returnTrue}
}

function menu_set_all_option_off {
   # Disables the 'All' option for the current working menu.
   # >>> menu_set_all_option_off 
   ${arcRequireBoundVariables}
   _menuRaiseWorkingMenuNotSet && ${returnFalse}
   eval "$(_menuLoad "${_g_workingMenuKey}")"
   MenuEnableAllOption=0
   objects_save_temporary_object "arcshell_menu" "${_g_workingMenuKey}"
   ${returnTrue}
}

function menu_set_all_option_to_default {
   # Enables the 'All' option and sets it to default selection for the current working menu.
   # >>> menu_set_all_option_to_default 
   ${arcRequireBoundVariables}
   _menuRaiseWorkingMenuNotSet && ${returnFalse}
   menu_set_all_option_on
   eval "$(_menuLoad "${_g_workingMenuKey}")"
   MenuAllOptionIsDefault=1
   objects_save_temporary_object "arcshell_menu" "${_g_workingMenuKey}"
   ${returnTrue}
}

function menu_set_auto_select_on {
   # Enables auto-select for the current working menu.
   # If the menu only contains one item it is automatically selected.
   # >>> menu_set_auto_select_on 
   ${arcRequireBoundVariables}
   _menuRaiseWorkingMenuNotSet && ${returnFalse}
   eval "$(_menuLoad "${_g_workingMenuKey}")"
   MenuAutoSelect=1
   objects_save_temporary_object "arcshell_menu" "${_g_workingMenuKey}"
   ${returnTrue}
}

function menu_set_auto_select_off {
   # Disables auto-select for the current working menu.
   # If the menu only contains one item it is not automatically selected.
   # >>> menu_set_auto_select_off 
   ${arcRequireBoundVariables}
   _menuRaiseWorkingMenuNotSet && ${returnFalse}
   eval "$(_menuLoad "${_g_workingMenuKey}")"
   MenuAutoSelect=0
   objects_save_temporary_object "arcshell_menu" "${_g_workingMenuKey}"
   ${returnTrue}
}

function _menuRaiseWorkingMenuNotSet {
   # Throw error and return true if the current working menu is not set.
   # >>> _menuRaiseWorkingMenuNotSet
   ${arcRequireBoundVariables}
   if [[ -z "${_g_workingMenuKey:-}" ]]; then
      _menuThrowError "Working menu is not set: $*: _menuRaiseWorkingMenuNotSet"
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function menu_add_text {
   # Add a text item and value to the current working menu.
   # >>> menu_add_text [-default] ["itemText"] "itemValue"
   # itemText: 
   # itemValue:
   ${arcRequireBoundVariables}
   typeset isDefaultItem itemCount
   isDefaultItem=0
   _menuRaiseWorkingMenuNotSet && ${returnFalse}
   while (( $# > 0)); do
      case "${1}" in
         "-default") isDefaultItem=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_arg_count "menu_add_text" "(( $# <= 2 ))" && ${returnFalse}
   utl_raise_invalid_arg_option "menu_add_text" "$*" && ${returnFalse}
   MenuItemText="${1}"
   MenuItemValue="${2:-${MenuItemText}}"
   MenuItemIsSubmenu=0
   MenuItemIsCommand=0
   _menuAddItemCount "${_g_workingMenuKey}"
   itemCount=$(_menuReturnItemCount "${_g_workingMenuKey}")
   _menuItemObjectModule > "${_menuDir}/${_g_workingMenuKey}/${itemCount}"
   if (( ${isDefaultItem} )); then
      eval "$(_menuLoad "${_g_workingMenuKey}")"
      MenuDefaultItemNumber=${itemCount}
      objects_save_temporary_object "arcshell_menu" "${_g_workingMenuKey}"
   fi
   ${returnTrue}
}

function menu_add_menu {
   # Add sub-menu and display text to current working menu.
   # >>> menu_add_menu "key" ["itemDisplay"]
   # key:
   # itemDisplay: 
   ${arcRequireBoundVariables}
   typeset isDefaultItem itemCount
   isDefaultItem=0
   _menuRaiseWorkingMenuNotSet && ${returnFalse}
   while (( $# > 0)); do
      case "${1}" in
         "-default") isDefaultItem=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_arg_count "menu_add_menu" "(( $# <= 2 ))" && ${returnFalse}
   utl_raise_invalid_arg_option "menu_add_menu" "$*" && ${returnFalse}
   MenuItemValue="${1}"
   MenuItemText="${2:-${MenuItemValue}}"
   MenuItemIsSubmenu=1
   MenuItemIsCommand=
   _menuAddItemCount "${_g_workingMenuKey}"
   itemCount="$(_menuReturnItemCount "${_g_workingMenuKey}")"
   _menuItemObjectModule > "${_menuDir}/${_g_workingMenuKey}/${itemCount}"
   if (( ${isDefaultItem} )); then
      eval "$(_menuLoad "${_g_workingMenuKey}")"
      MenuDefaultItemNumber=${itemCount}
      objects_save_temporary_object "arcshell_menu" "${_g_workingMenuKey}"
   fi
   ${returnTrue}
}

function _menuReturnItemCount {
   # Return the number of items in the menu.
   # Note: Does not include the 'All' or 'q' options in the count.
   # >>> _menuReturnItemCount "key"
   # key: 
   typeset key
   key="${1}"
   # Use file_line_count function. 'wc -l' pads output on Solaris.
   file_line_count "${_menuDir}/${key}/itemCount"
}

function _menuAddItemCount {
   # Add 1 to the current menu item count.
   # >>> _menuAddItemCount "key"
   # key: 
   typeset key
   key="${1}"
   echo 1 >> "${_menuDir}/${key}/itemCount"
}

function menu_add_command {
   # Add a command and display value as a menu item.
   # >>> menu_add_menu "command" ["itemDisplay"]
   # command: Command string to run.
   # itemDisplay: Display text.
   ${arcRequireBoundVariables}
   typeset isDefaultItem itemCount
   isDefaultItem=0
   _menuRaiseWorkingMenuNotSet && ${returnFalse}
   while (( $# > 0)); do
      case "${1}" in
         "-default") isDefaultItem=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "menu_add_command" "(( $# <= 2 ))" "$*" && ${returnFalse}
   MenuItemValue="${1}"
   MenuItemText="${2:-${MenuItemValue}}"
   MenuItemIsSubmenu=0
   MenuItemIsCommand=1
   _menuAddItemCount "${_g_workingMenuKey}"
   itemCount="$(_menuReturnItemCount "${_g_workingMenuKey}")"
   _menuItemObjectModule > "${_menuDir}/${_g_workingMenuKey}/${itemCount}"
   if (( ${isDefaultItem} )); then
      eval "$(_menuLoad "${_g_workingMenuKey}")"
      MenuDefaultItemNumber=${itemCount}
      objects_save_temporary_object "arcshell_menu" "${_g_workingMenuKey}"
   fi
   ${returnTrue}
}

function menu_delete {
   # Delete a specified menu or the current working menu.
   # >>> menu_delete ["key"]
   # key: 
   ${arcRequireBoundVariables}
   typeset key
   debug2 "menu_delete: $*"
   if is_defined "${1:-}"; then
      key="${1}"
   else
      _menuRaiseWorkingMenuNotSet && ${returnFalse}
      key="${_g_workingMenuKey}"
      menu_unset
   fi
   _menuDeleteMenu "${key}" 
   ${returnTrue}
}

function menu_unset {
   #
   # >>>
   _g_workingMenuKey=
}

function menu_was_quit {
   # Return true if the the last response was quit for the given menu.
   # >>> menu_was_quit "key"
   ${arcRequireBoundVariables}
   typeset key
   key="${1}"
   debug2 "menu_was_quit: $*"
   _menuRaiseMenuNotFound "${key}" && ${returnFalse}
   if [[ "$(cat "${_menuDir}/${key}/tty${_tty}/lastResponse")" == "q" ]]; then
      debug2 "True: menu_was_quit"
      ${returnTrue}
   else
      debug2 "False: menu_was_quit"
      ${returnFalse}
   fi
}

function menu_show {
   # Show the current menu.
   # >>> menu_show [-hide] [-select X] [-parent "X"] ["key"]
   # -hide: Hide menu (for testing only).
   # -select: Pre-selected item number (for testing only).
   # -parent: Parent menu key.
   # -quit: Quits menu after first item is selected.
   ${arcRequireBoundVariables}
   debug3 "menu_show: $*"
   typeset x menuItemCount key userResponse hideMenu i allOptionItemNumber defaultResponse autoSelectedItem allOptionItemNumber parentMenuKey quitMenuOnSelection
   hideMenu=0
   autoSelectedItem=
   parentMenuKey=
   quitMenuOnSelection=0
   while (( $# > 0)); do
      case "${1}" in
         "-hide") hideMenu=1 ;;
         "-select") shift; autoSelectedItem=${1} ;;
         "-parent") shift; parentMenuKey="${1}" ;;
         "-quit") quitMenuOnSelection=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "menu_show" "(( $# <= 1 ))" "$*" && ${returnFalse} 
   if [[ -n "${1:-}" ]]; then 
      key="${1}"
   else
      key="${_g_workingMenuKey}"
   fi

   _menuRaiseMenuNotFound "${key}" && ${returnFalse}

   debug3 "parentMenuKey=${parentMenuKey}"
   eval "$(_menuLoad "${key}")"
   mkdir -p "${_menuDir}/${key}/tty${_tty}"
   cp /dev/null "${_menuDir}/${key}/tty${_tty}/selectedItemTextValues"
   cp /dev/null "${_menuDir}/${key}/tty${_tty}/selectedItems"
   cp /dev/null "${_menuDir}/${key}/tty${_tty}/lastResponse"
   menuItemCount=$(_menuReturnItemCount "${key}")
   if (( ${MenuAutoSelect} && ${menuItemCount} == 1 )); then
      autoSelectedItem=${menuItemCount}
   fi
   if (( ${menuItemCount} )); then
      if ! (( ${hideMenu} )); then
         _menuDisplayTitle "${MenuTitle}"
         while read i; do
            . "${_menuDir}/${key}/${i}"
            printf "%-5s %s\n" "[ ${i} ]" "${MenuItemText}"
         done < <(_menuGetItemRange "${key}")
         if (( ${MenuEnableAllOption} )); then
            ((menuItemCount=menuItemCount+1))
            allOptionItemNumber=${menuItemCount}
            (( ${MenuAllOptionIsDefault} )) && defaultResponse=${menuItemCount}
            printf "%-5s %s\n" "[ ${menuItemCount} ]" "All"     
         fi
         ! (( ${MenuIsEasy} )) && printf "%-5s %s\n" "[ q ]" "Quit"
         echo ""
         if [[ -n "${defaultResponse:-}" ]]; then
            printf "Select [${defaultResponse}]: "
         else
            printf "Select: "
         fi
         if [[ -z "${autoSelectedItem:-}" ]]; then
            read userResponse < /dev/tty 
         else
            userResponse=${autoSelectedItem}
            echo ""
         fi
      fi
   else
      userResponse="q"
   fi

   is_not_defined "${userResponse}" && userResponse="${defaultResponse:-}"

   echo "${userResponse}" >> "${_menuDir}/${key}/tty${_tty}/lastResponse"

   debug3 "userResponse=${userResponse}"
   if num_is_num ${userResponse}; then
      # User selected 'All'.
      if (( ${userResponse} > 0 && ${userResponse} == ${allOptionItemNumber:-0} )); then
         menu_list_all_items "${key}" > "${_menuDir}/${key}/tty${_tty}/selectedItemTextValues"
         _menuGetItemRange "${key}" > "${_menuDir}/${key}/tty${_tty}/selectedItems"
         _menuRunCommandsForSelectedItems "${key}"
      # Valid numeric response.
      elif (( ${userResponse} >= 1 && ${userResponse} <= ${menuItemCount} )); then
         _menuSetSelectedItem "${key}" ${userResponse}
         . "${_menuDir}/${key}/${userResponse}"
         if (( ${MenuItemIsSubmenu} )); then
            (( ! ${quitMenuOnSelection} )) && menu_show -parent "${key}" "${MenuItemValue}"
         elif (( ${MenuItemIsCommand} )); then
            _menuRunCommandsForSelectedItems "${key}"
         fi
      # Invalid numeric response.
      else
         if [[ -n "${autoSelectedItem}" ]]; then
            _menuThrowError "Can't pre-select an invalid option: $*: menu_show"
            ${returnFalse}
         fi
      fi
      if [[ -z "${autoSelectedItem:-}" ]] ; then
         (( ! ${quitMenuOnSelection} )) && menu_show "${key}" 
      fi
      ${returnTrue}
   elif [[ "${userResponse}" == "q" ]]; then
      debug3 "userResponse=q"
      if [[ -n "${parentMenuKey:-}" ]]; then
         debug3 "quit and parent key is set: ${parentMenuKey}"
         #menu_show "${parentMenuKey}"
         ${returnTrue}
      fi
   fi
   if [[ -n "${parentMenuKey:-}" ]]; then
      debug3 "parent key is set: ${parentMenuKey}"
      menu_show "${parentMenuKey}"
      ${returnTrue}
   fi
   debug2 "returning at end of function"
   ${returnTrue}
}

function _menuRunCommandsForSelectedItems {
   # Execute command associated with each selected item for given menu, if any.
   # >>> _menuRunCommandsForSelectedItems "${key}" 
   ${arcRequireBoundVariables}
   debug2 "_menuRunCommandsForSelectedItems: $*"
   typeset x key tmpFile
   key="${1}" 
   _menuRaiseMenuNotFound "${key}" && ${returnFalse}
   tmpFile="$(mktempf)"
   eval "$(_menuLoad "${key}")"
   while read x; do
      . "${_menuDir}/${key}/${x}"
      if (( ${MenuItemIsCommand} )); then 
         echo "${MenuItemValue}" >> "${tmpFile}"
      fi
   done < "${_menuDir}/${key}/tty${_tty}/selectedItems"
   # Don't try to execute in the loop. 'vi' commands complain of not being run
   # from a terminal and close the terminal on Solaris at least.
   chmod 700 "${tmpFile}"
   . "${tmpFile}"
   rm "${tmpFile}"
   ${returnTrue}
}

function _menuLoad {
   # Return the string used to load the menu.
   # >>> eval "$(_menuLoad "key")"
   typeset key 
   key="${1}"
   objects_load_temporary_object "arcshell_menu" "${key}"
}

function menu_get_item_count {
   # Returns the number of items from the current working menu.
   # >>> menu_get_item_count
   ${arcRequireBoundVariables}
   _menuRaiseWorkingMenuNotSet && ${returnFalse}
   _menuReturnItemCount "${_g_workingMenuKey}"
   ${returnTrue} 
}

function _menuDisplayTitle {
   # Prints the menu title to standard out.
   # >>> _menuDisplayTitle "title"
   ${arcRequireBoundVariables}
   typeset title 
   title="${1}"
   cat <<EOF
   
=====================================================================
${title}
=====================================================================

EOF
}

function _menuPrintMenuItems {
   # Prints the menu items to standard output.
   # >>> _menuPrintMenuItems "key"
   ${arcRequireBoundVariables}
   typeset i key 
   key="${1}"
   eval "$(_menuLoad "${key}")"
   while read i; do
      . "${_menuDir}/${key}/${i}"
      printf "%-5s %s\n" "[ ${i} ]" "${MenuItemText}"
   done <<< "$(_menuGetItemRange "${key}")"
}

function _menuSetSelectedItem {
   # Register an item number as selected for the given menu.
   # >>> _menuSetSelectedItem "key" "itemNumber"
   ${arcRequireBoundVariables}
   debug2 "_menuSetSelectedItem: $*"
   typeset key itemNumber 
   key="${1}"
   itemNumber=${2}
   . "${_menuDir}/${key}/${itemNumber}"
   echo "${MenuItemValue}" > "${_menuDir}/${key}/tty${_tty}/selectedItemTextValues"
   echo ${itemNumber} > "${_menuDir}/${key}/tty${_tty}/selectedItems"
}

function _menuAutoSelectIfSingleItemMenu {
   ${arcRequireBoundVariables}
   typeset key itemNumber 
   key="${1}"
   if (( $(_menuReturnItemCount "${key}") == 1 )); then
      _menuSetSelectedItem "${key}" 1
   else
      _menuThrowError "Can not select only item from a menu with more than one item: _menuAutoSelectIfSingleItemMenu "
   fi
}

function _menuRaiseMenuNotFound {
   ${arcRequireBoundVariables}
   typeset key
   key="${1}"
   if ! menu_does_menu_exist "${key}"; then
      _menuThrowError "Menu not found: $*: _menuRaiseMenuNotFound"
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function _menuDeleteMenu {
   # Delete a menu. 
   # >>> _menuDeleteMenu "${key}"
   # ```
   # _menuDeleteMenu "TestMenu"
   # ```
   ${arcRequireBoundVariables}
   typeset key 
   debug2 "_menuDeleteMenu: $*"
   key="${1}" 
   str_raise_not_a_key_str "key" "${key}" && ${returnFalse}  
   if [[ -d "${_menuDir}/${key}" ]]; then
      rm -rf "${_menuDir}/${key}"
   fi
   objects_delete_temporary_object "arcshell_menu" "${key}"
   ${returnTrue}
}

function menu_delete_all_menus {
   # Delete all menus owned by the current Unix process ID.
   # >>> menu_delete_all_menus
   # ```
   # menu_delete_all_menus
   # ```
   [[ -d "${_menuDir}" ]] && rm -rf "${_menuDir}"
}

function menu_get_selected_item {
   # Get the text value for the last selected item. 
   #
   # > This assumes that the -all option was not available. If the -all option
   # >  was used you should be using the menu_list_selected_items function.
   #
   # >>> menu_get_selected_item "key" 
   # 
   # **Example**
   # ```
   # x=$(menu_get_selected_item "TestMenu")
   # echo "You're response was ${x}."
   # ```
   ${arcRequireBoundVariables}
   debug2 "menu_get_selected_item: $*"
   typeset key
   key="${1}" 
   menu_list_selected_items "${key}" | tail -1
}

function menu_list_selected_items {
   # Lists the text values of the selected items.
   # >>> menu_list_selected_items "key" 
   # **Example**
   # ```
   # menu_list_selected_items "TestMenu"
   # ```
   ${arcRequireBoundVariables}
   debug2 "menu_list_selected_items: $*"
   typeset key
   key="${1}" 
   if menu_does_menu_exist "${key}"; then
      eval "$(_menuLoad "${key}")"
      cat "${_menuDir}/${key}/tty${_tty}/selectedItemTextValues"
   else
      _menuThrowError "Menu does not exist: $*: menu_list_selected_items"
   fi
}

function menu_list_all_items {
   # Return a list of menu items.
   # >>> menu_list_all_items "key" 
   ${arcRequireBoundVariables}
   debug2 "menu_list_all_items: $*"
   typeset key x
   key="${1}"
   eval "$(_menuLoad "${key}")"
   (( $(_menuReturnItemCount "${key}") == 0 )) && return
   while read x; do 
      . "${_menuDir}/${key}/${x}"
      echo "${MenuItemValue}"
   done < <(_menuGetItemRange "${key}")
}

function menu_get_selected_item_count {
   # Return the count of selected items for a menu.
   # >>> menu_get_selected_item_count "key" 
   ${arcRequireBoundVariables}
   debug2 "menu_get_selected_item_count: $*"
   typeset key
   key="${1}" 
   cat "${_menuDir}/${key}/tty${_tty}/selectedItems" | wc -l
   ${returnTrue} 
}

function menu_does_menu_exist {
   # Return true if menu exists.
   # >>> menu_does_menu_exist "key"
   ${arcRequireBoundVariables}
   debug2 "menu_does_menu_exist: $*"
   typeset key
   key="${1:-'DoesNotExist'}"
   if objects_does_temporary_object_exist "arcshell_menu" "${key}"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _menuGetItemRange {
   # Lists the menu item numbers for each menu option. 
   # >>> _menuGetItemRange "key" 
   ${arcRequireBoundVariables}
   debug3 "_menuGetItemRange: $*"
   typeset key
   key="${1}" 
   eval "$(_menuLoad "${key}")"
   num_range 1 $(_menuReturnItemCount "${key}") 
}

function _menuThrowError {
   # Generic error handler. Message is returned to standard error.
   # >>> _menuThrowError "${errorText}"
   throw_error "arcshell_menu.sh" "${1}"
}

