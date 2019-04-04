> If your bug has a one in a million chance of happening, it'll happen next Tuesday. -- Anonymous

# Boot

**Things we need to load or do first.**



## Reference


### boot_return_with_shbang
Return the file contents with a shbang added for Bash or Korn shell.
```bash
> boot_return_with_shbang "file"
```

### stdout_banner
Returns a simple unix commented banner to ```stdout```.
```bash
> stdout_banner "str"
# str: Banner string.
```

### stderr_banner
Returns a simple unix commented banner to ```stderr```.
```bash
> stderr_banner "str"
# str: Banner string.
```

### boot_is_valid_ksh
Return true if current shell is ksh.
```bash
> boot_is_valid_ksh
```

### boot_is_valid_bash
Return true if current shell is bash.
```bash
> boot_is_valid_bash
```

### boot_return_shell_type
Return a string to identify the shell type, either 'bash' or 'ksh'.
```bash
> boot_return_shell_type
# Check for ksh in even BASH variable has been exported to ksh. I don't think
# it works the same way going from ksh to bash.
```

### boot_is_dir_within_dir
Return true if first directory is a subdirectory of second directory.
```bash
> boot_is_dir_within_dir "first directory" "second directory"
```

### throw_error
Returns text string as a "sanelog" ERROR string to standard error.
```bash
> throw_error "sourceText" "errorText"
# sourceText: Text to identify the source of the error, often library file name.
# errorText: Text of error message.
```

### throw_message
Returns text string as a "sanelog" MESSAGE string to standard error.
```bash
> throw_message "messageSource" "messageText"
# messageSource: Text to identify the source of the message, often library file name.
# messageText: Text of message.
```

### sanelog
Applies log file formating to inputs and returns to standard out.
> This function influenced by logsna project. https://github.com/rspivak/logsna
```bash
> sanelog "keywordText" "sourceText" "logText"
```

### boot_get_file_blurb
Return the blurb at the top of most modules.
```bash
> boot_get_file_blurb
```

### boot_return_tty_device
Returns the tty ID number. Returns zero if "not a tty".
```bash
> boot_return_tty_device
```

### is_tty_device
Return true if device is a tty device.
is_tty_device

### boot_list_functions
List all of the functions in a file.
```bash
> boot_list_functions "file"
```

### boot_list_arcshell_homes
Return a list of the Archell homes (application, global, and user).
```bash
> boot_list_arcshell_homes
```

### boot_is_file_gz_zipped
Return true if the file ends in .gz.
```bash
> boot_is_file_gz_zipped "file"
```

### boot_is_file_compressed
Return true if the file ends in .Z.
```bash
> boot_is_file_compressed "file"
```

### boot_is_file_archive
Return true if the file ends in .tar.
```bash
> boot_is_file_archive "file"
```

### boot_is_program_found
Return true if program appears to be available.
```bash
> boot_is_program_found "program name or path"
```

### boot_raise_program_not_found
Throw error and return true if the program is not found.
```bash
> boot_raise_program_not_found "program"
```

### boot_is_sunos

### boot_does_function_exist
Return true if the function is loaded in the environment.
```bash
> boot_does_function_exist "function name"
```

### boot_hello_sunos

```bash
> boot_hello_sunos
```

### boot_is_aux_instance
Return true if the current ArcShell instance is an auxilliary instance.
```bash
> boot_is_aux_instance
```

