# Compiler
**Transforms modules with multiple dependencies into single executable files.**

This module is a prototype/proof of concept.



## Reference


### compiler_start
Starts a new compiler session.
```bash
> compiler_start "group"
# group: File group name.
```

### compiler_stop
Terminates the current compiler session.
```bash
> compiler_stop
```

### compiler_include
Input here is appended to the header of the compiled files.
```bash
> compiler_include [-stdin | "file"]
```

### compiler_compile
Compile the currently set file.
```bash
> compiler_compile [-debug] [-tests] "source_file" "target_file"
# -debug: Include debug calls.
# -tests: Include test functions.
# source_file:
# target_file:
```

### compiler_create_group
Create a compiler file group.
```bash
> compiler_create_group "group"
# group: Name of group. Must be a ```key string```.
```

### compiler_define_group
Associates the group with a list of files.
```bash
> compiler_define_group [-stdin | "file"]
# file: A file containing a list of files which define the group.
```

### compiler_generate_resources
Generate maps and requirements which are needed to compile libraries.
```bash
> compiler_generate_resources ["regex"]
```

### compiler_delete_group
Delete a compiler file group and all associated resources.
```bash
> compiler_delete_group ["group"]
```

### compiler_does_group_exist
Return true if compiler fil egroup exists.
```bash
> compiler_does_group_exist "group"
```

### compiler_set_group
Set the global file group variable to the defined value.
```bash
> compiler_set_group "group"
```

### compiler_unset
Unset the global file group variable.
```bash
> compiler_unset
```

### compiler_banner
Returns a simple banner/break.
```bash
> compiler_banner "str"
# str: Any string.
```

