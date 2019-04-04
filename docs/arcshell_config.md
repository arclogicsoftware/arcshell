> I'm not a great programmer; I'm just a good programmer with great habits. -- Kent Beck

# Configuration

**Manage configuration files.**

This module can be used to interact with a configuration files and ArcShell configuration objects.

The ```config_merge``` function is used to merge settings assigned in "old_file" to "new_file" without disturbing any other lines or values in "new_file". This function can't merge variable values that span more than one line.

The  ```config_file_*``` functions are a bit more sophisticated in that they do work with variable values that span multiple lines. The process of of assigning values is under the control of the programmer.

Finally the other ```config_*``` functions are meant to interact specifically with ArcShell configuration objects.

These objects are stored in one or more of the ```config``` folders for each of the three ArcShell homes.

```
${arcHome}/config
${arcGlobalHome}/config
${arcUserHome}/config
```
Depending on the design implemented the module may load the first configuration file found or it may all of the configuration files. This can be accomplished in a top-down order, or bottom up.

ArcShell configuration files are often simply shell scripts containing variable assignments. As such you are free to use valid shell commands to determine the settings of these assignments.



## Reference


### config_merge
Updates new_file by merging assignments from old_file where there are common variables.
```bash
> config_merge "new_file" "old_file"
# new_file: Any file containing "parameter=value" assignments.
# old_file: The configuration file to use existing values from.
```

### config_file_set
Loads the configuration we want to work with from a file.
```bash
> config_file_set "file"
```

### config_file_set_parm
Sets an existing parameter value in the working copy of the config file..
```bash
> config_file_set_parm "parameter" "value"
```

### config_file_get_parm
Returns the value of a parameter from the working configuration file.
```bash
> config_file_get_parm "parameter"
```

### config_file_save
Saves the config by activating the working config file.
```bash
> config_file_save
```

### config_file_cancel
Cancel working with the current configuration file.
```bash
> config_file_cancel
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

### config_load_all_objects
Return the strings required to source in the objects's configuration file.
```bash
> config_load_all_objects [-reverse,-r] "object_type" "object_name"
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

