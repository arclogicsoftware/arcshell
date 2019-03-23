# arcshell_shfile.sh



## Reference


### shfile_set
Sets the working file.
```bash
> shfile_set "file"
```

### shfile_unset
Unsets the working file.
```bash
> shfile_unset
```

### shfile_check_params



### shfile_list_functions
List all of the functions in a file.
```bash
> shfile_ls
```

### shfile_does_function_exist



### shfile_return_function_body
Returns the function body. Removes first 3 characters which should be spaces.
```bash
> shfile_return_function_body "function name"
```

### shfile_return_docs
Returns the function documentation from a file.
```bash
> utl_get_function_doc "function name"
```

### shfile_return_function_def
Returns a function definition from a file.
```bash
> shfile_return_function_def "function name"
```

### shfile_remove_function



### shfile_is_function_loaded
Return true if the function is loaded in the environment.
```bash
> shfile_is_function_loaded "function name"
```

