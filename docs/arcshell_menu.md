> Any fool can write code that a computer can understand. Good programmers write code that humans can understand. -- Martin Fowler

# Menus

**Builds rich command line menu systems that are dynamic.**



## Reference


### menu_create
Create or recreate a menu and sets the 'working' menu.
```bash
> menu_create "key" "title"
# key: Key string used to reference the menu.
# title: Title string.
```

### menu_set
Sets the current working menu.
```bash
> menu_set "key"
```

### menu_set_all_option_on
Enables the 'All' option for the current working menu.
```bash
> menu_set_all_option_on
```

### menu_set_all_option_off
Disables the 'All' option for the current working menu.
```bash
> menu_set_all_option_off
```

### menu_set_all_option_to_default
Enables the 'All' option and sets it to default selection for the current working menu.
```bash
> menu_set_all_option_to_default
```

### menu_set_auto_select_on
Enables auto-select for the current working menu.
If the menu only contains one item it is automatically selected.
```bash
> menu_set_auto_select_on
```

### menu_set_auto_select_off
Disables auto-select for the current working menu.
If the menu only contains one item it is not automatically selected.
```bash
> menu_set_auto_select_off
```

### menu_add_text
Add a text item and value to the current working menu.
```bash
> menu_add_text [-default] ["itemText"] "itemValue"
# itemText:
# itemValue:
```

### menu_add_menu
Add sub-menu and display text to current working menu.
```bash
> menu_add_menu "key" ["itemDisplay"]
# key:
# itemDisplay:
```

### menu_add_command
Add a command and display value as a menu item.
```bash
> menu_add_menu "command" ["itemDisplay"]
# command: Command string to run.
# itemDisplay: Display text.
```

### menu_delete
Delete a specified menu or the current working menu.
```bash
> menu_delete ["key"]
# key:
```

### menu_unset

```bash
> 
```

### menu_was_quit
Return true if the the last response was quit for the given menu.
```bash
> menu_was_quit "key"
```

### menu_show
Show the current menu.
```bash
> menu_show [-hide] [-select X] [-parent "X"] ["key"]
# -hide: Hide menu (for testing only).
# -select: Pre-selected item number (for testing only).
# -parent: Parent menu key.
# -quit: Quits menu after first item is selected.
```

### menu_get_item_count
Returns the number of items from the current working menu.
```bash
> menu_get_item_count
```

### menu_delete_all_menus
Delete all menus owned by the current Unix process ID.
```bash
> menu_delete_all_menus
# ```
# menu_delete_all_menus
# ```
```

### menu_get_selected_item
Get the text value for the last selected item.

> This assumes that the -all option was not available. If the -all option
> was used you should be using the menu_list_selected_items function.

```bash
> menu_get_selected_item "key"
# 
# **Example**
# ```
# x=$(menu_get_selected_item "TestMenu")
# echo "You're response was ${x}."
# ```
```

### menu_list_selected_items
Lists the text values of the selected items.
```bash
> menu_list_selected_items "key"
# **Example**
# ```
# menu_list_selected_items "TestMenu"
# ```
```

### menu_list_all_items
Return a list of menu items.
```bash
> menu_list_all_items "key"
```

### menu_get_selected_item_count
Return the count of selected items for a menu.
```bash
> menu_get_selected_item_count "key"
```

### menu_does_menu_exist
Return true if menu exists.
```bash
> menu_does_menu_exist "key"
```

