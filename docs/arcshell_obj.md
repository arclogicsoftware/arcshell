# arcshell_obj.sh

## Reference


### objects_register_object_model
Links a function which defines the object model with the model name.
```bash
> objects_register_object_model "modelName" "functionName"
```

### objects_init_object
Return the text required to set all values associated with a model to null.
```bash
> objects_init_object "modelName"
```

### objects_does_object_model_exist
Return true if the model exists
```bash
> objects_does_object_model_exist "modelName"
```

### objects_create_user_object
Create a local object.
```bash
> objects_create_user_object "modelName" "objectName"
```

### objects_create_global_object
Create a global object.
```bash
> objects_create_global_object "modelName" "objectName"
```

### objects_create_delivered_object
Create a delivered object.
```bash
> objects_create_delivered_object "modelName" "objectName"
```

### objects_create_temporary_object
Create a temporary object.
```bash
> objects_create_temporary_object "modelName" "objectName"
```

### objects_save_object
Save an object.
```bash
> objects_save_object "modelName" "objectName"
```

### objects_save_temporary_object
Save a temporary object.
```bash
> objects_save_temporary_object "modelName" "objectName"
```

### objects_does_object_exist
Return true if an object exists.
```bash
> objects_does_object_exist "modelName" "objectName"
```

### objects_does_user_object_exist
Return true if local object of object type exists.
```bash
> objects_does_user_object_exist "objectType" "objectName"
```

### objects_does_global_object_exist
Return true if global object of object type exists.
```bash
> objects_does_global_object_exist "objectType" "objectName"
```

### objects_does_delivered_object_exist
Return true if delivered object of object type exists.
```bash
> objects_does_delivered_object_exist "objectType" "objectName"
```

### objects_does_temporary_object_exist
Return true if temporary object of object type exists.
```bash
> objects_does_temporary_object_exist "objectType" "objectName"
```

### objects_list_objects

### objects_list_user_objects

### objects_list_global_objects

### objects_list_delivered_objects

### objects_list_temporary_objects
Return a list of temporary objects.
```bash
> objects_list_temporary_objects "modelName"
```

### objects_edit_object
Edit an object file directory in the defined \${EDITOR}.
```bash
> objects_edit_object "modelName" "objectName"
```

### objects_show_object
Return the contents of the file which defines an object.
```bash
> objects_show_object "modelName" "objectName"
```

### objects_load_object

### objects_load_delivered_object

### objects_load_global_object

### objects_load_user_object

### objects_load_temporary_object
Return the string required to source in a temporary object file.
```bash
> objects_load_temporary_object "modelName" "objectName"
```

### objects_delete_object_model
Deletes the object model and all related object instances.
```bash
> objects_delete_object_model "modelName"
```

### objects_delete_object

### objects_delete_user_object

### objects_delete_global_object

### objects_delete_delivered_object

### objects_delete_temporary_object
Delete a temporary object by removing the file that contains the object details.
```bash
> objects_delete_temporary_object "modelName" "objectName"
```

### objects_update_objects
Rebuilds all instances of a model using the current definition.
```bash
> objects_update_objects "modelName"
```

### objects_update_delivered_objects


### objects_update_global_objects


### objects_update_user_objects


### objects_list_objects_pretty
Return a formated list of the system objects.

### objects_list_object_models
Return a list of the available system object types.
```bash
> objects_list_object_models
```

