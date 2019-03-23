# arcshell_config.sh



## Reference


### config_run_config_function
Runs the __config* function in a file if it exists.
```bash
> config_run_config_function "file"
```

### config_merge_files
Modify ```new_file``` by merging assignments from ```old_file``` for matching variables.
```bash
> config_merge_files "new_file" "old_file"
# new_file: Any file containing "parameter=value" assignments.
# old_file: The configuration file to use existing values from.
```

### config_set_file
Loads the configuration we want to work with from a file.
```bash
> config_set_file "file"
```

### config_set_parameter
Sets an existing ```parameter``` ```value``` in the working copy of the config file..
```bash
> config_set_parameter "parameter" "value"
```

### config_get_parameter
Returns the value of a parameter from the working configuration file.
```bash
> config_get_parameter "parameter"
```

### config_save
Saves the config by activating the working config file.
```bash
> config_save
```

### config_cancel
Cancel working with the current configuration file.
```bash
> config_cancel
```

### config_show_config
Returns some quick/basic info about the objects in the config.
```bash
> config_show_config "object_type"
```

### config_edit_object
Open the configuration file for the object in the default editor.
```bash
> config_edit_object "object_type" "object_name"
```

### config_load_object
Return the string required to source in the objects's configuration file.
```bash
> config_load_object "object_type" "object_name"
```

### config_return_all_paths_for_object
Return the full path to all files of object type and object name.
```bash
> config_return_all_paths_for_object "object_type" "object_name"
```

### config_return_object_path
Return the full path to the file which defines the "object".
```bash
> config_return_object_path "object_type" "object_name"
# -a: Return all object paths in narrowing order of scope.
```

### config_copy_object
Copies an object.
```bash
> config_copy_object "object_type" "object_name" "new_name"
```

### config_list_all_objects
Returns each object of "object type".
```bash
> config_list_all_objects [-l|-a] "object_type"
# -l: Returns full path to file which defines the object.
# -a: Returns all objects, even if they are defined more than once.
```

### config_list_all_object_types
Return the list of object types that are available.
```bash
> config_list_all_object_types
```

### config_object_count
Return the number of objects defined.
```bash
> config_object_count "object_type"
```

### config_does_object_exist
Return true if the object exists.
```bash
> config_does_object_exist "object_type" "object_name"
```

### config_delete_object
Delete an object by name.
```bash
> config_delete_object "object_type" "object_name"
```

