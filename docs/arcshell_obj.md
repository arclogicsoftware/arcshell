# Objects
**Manages object styled data structures.**

Object models are defined using an ArcShell configuration item. You can review existing definitions here. Do not modify any of the delivered items unless you know what you are doing.
```
ls "${arcHome}/config/object_models/"
```
Your custom object models belong in the Global or User configuration file locations.

* "${arcGlobalHome}/config/object_models/"
* "${arcuUserHome}/config/object_models/"

You can then load, modify, and save records based upon the object models you create using this module.

## Example(s)
```bash

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
```

## Reference


### objects_register_object_model_file
Registers an object model using a file instead of a function.
```bash
> objects_register_object_model_file "modelName" "filePath"
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
Create an object.
```bash
> objects_create_user_object "modelName" "objectName"
```

### objects_create_global_object
Create an object.
```bash
> objects_create_global_object "modelName" "objectName"
```

### objects_create_delivered_object
Create an object.
```bash
> objects_create_delivered_object "modelName" "objectName"
```

### objects_create_temporary_object
Create an object.
```bash
> objects_create_temporary_object "modelName" "objectName"
```

### objects_save_object
Save an object.
```bash
> objects_save_object "modelName" "objectName"
```

### objects_save_temporary_object
Save an object.
```bash
> objects_save_temporary_object "modelName" "objectName"
```

### objects_does_object_exist
Return true if object exists.
```bash
> objects_does_object_exist "objectType" "objectName"
```

### objects_does_user_object_exist
Return true if object exists.
```bash
> objects_does_user_object_exist "objectType" "objectName"
```

### objects_does_global_object_exist
Return true if object exists.
```bash
> objects_does_global_object_exist "objectType" "objectName"
```

### objects_does_delivered_object_exist
Return true if object exists.
```bash
> objects_does_delivered_object_exist "objectType" "objectName"
```

### objects_does_temporary_object_exist
Return true if object exists.
```bash
> objects_does_temporary_object_exist "objectType" "objectName"
```

### objects_list_objects
Return a list of objects.
```bash
> objects_list_objects "modelName"
```

### objects_list_user_objects
Return a list of objects.
```bash
> objects_list_user_objects "modelName"
```

### objects_list_global_objects
Return a list of objects.
```bash
> objects_list_global_objects "modelName"
```

### objects_list_delivered_objects
Return a list of objects.
```bash
> objects_list_delivered_objects "modelName"
```

### objects_list_temporary_objects
Return a list of objects.
```bash
> objects_list_temporary_objects "modelName"
```

### objects_load_object
Return string used to load an object.
```bash
> eval "$(objects_load_object "modelName" "objectName")"
```

### objects_load_delivered_object
Return string used to load an object.
```bash
> eval "$(objects_load_delivered_object "modelName" "objectName")"
```

### objects_load_global_object
Return string used to load an object.
```bash
> eval "$(objects_load_global_object "modelName" "objectName")"
```

### objects_load_user_object
Return string used to load an object.
```bash
> eval "$(objects_load_user_object "modelName" "objectName")"
```

### objects_load_temporary_object
Return string used to load an object.
```bash
> eval "$(objects_load_temporary_object "modelName" "objectName")"
```

### objects_delete_object_model
Deletes the object model and all related object instances.
```bash
> objects_delete_object_model "modelName"
```

### objects_delete_object
Deletes an object.
```bash
> objects_delete_object "modelName" "objectName"
```

### objects_delete_user_object
Deletes an object.
```bash
> objects_delete_user_object "modelName" "objectName"
```

### objects_delete_global_object
Deletes an object.
```bash
> objects_delete_global_object "modelName" "objectName"
```

### objects_delete_delivered_object
Deletes an object.
```bash
> objects_delete_delivered_object "modelName" "objectName"
```

### objects_delete_temporary_object
Deletes an object.
```bash
> objects_delete_temporary_object "modelName" "objectName"
```

### objects_update_objects
Rebuilds all instances of a model using the current definition.
```bash
> objects_update_objects "modelName"
```

