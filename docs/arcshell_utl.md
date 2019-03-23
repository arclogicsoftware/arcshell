# arcshell_utl.sh



## Reference


### utl_return_matching_loaded_functions
Return the list of matching function names from the current environment.
```bash
> utl_return_matching_loaded_functions ["regex"]
# regex: Functions matching the regular expression are returned.
```

### utl_confirm
Return true if use response with a "truthy" value.
utl_confirm
__utl_confirm_skip: If this variable is set to 1 confirmations are skipped.

### utl_format_tags
Formats the list of tags per standard ArcShell rules for tags.
```bash
> utl_format_tags "tags"
# tags: A list of tags.
```

### utl_format_single_item_list
Turns a list with commas or spaces into a single list with commas.
```bash
> utl_format_single_item_list "tags"
# tags: A list of tags.
```

### utl_get_function_body
Returns the function body. Removes first 3 characters which should be spaces.
```bash
> utl_get_function_body "file_path" "func_name"
# file_path: Path to file.
# func_name: Name of function.
```

### utl_get_function_def
Returns a function definition from a file.
```bash
> utl_get_function_def "file_path" "func_name"
# file_path: Path to file.
# func_name: Name of function.
```

### utl_get_function_doc
Returns the function documentation from a file.
```bash
> utl_get_function_doc "file_path" "func_name"
# file_path: Path to file.
# func_name: Name of function.
```

### utl_inspect_model_definition

```bash
> utl_inspect_model_definition "model_definition" "actual_definition"
```

### utl_add_dirs_to_unix_path
Adds a bunch of values to the current path string if they don't exist and returns the new string.
```bash
> utl_add_dirs_to_unix_path "path" "path" "path"
# path: One or more values you would like to add to the path.
```

### utl_zip_file
Zip a file using gzip or compress depending on which program is available.
```bash
> utl_zip_file "file"
```

### utl_zip_get_last_file_path
Return the full path to the last file compressed or zipped.
utl_zip_get_last_file_path

### utl_raise_empty_var
Throw error and return true if $1 is not set.
```bash
> utl_raise_empty_var "error_message" "${check_variable}"
# error_message: The message to display if the second argument is empty/null/undefined.
# check_variable: The variable itself is passed in here.
```

### utl_does_file_end_with_newline
Return true if the file ends with a new line character.
```bash
> utl_does_file_end_with_newline "file"
```

### utl_add_missing_newline_to_end_of_file
Adds \n to the end of a file if it is missing.
```bash
> utl_add_missing_newline_to_end_of_file "file"
```

### utl_raise_invalid_option
Checks for some common issues when processing command line args.
```bash
> utl_raise_invalid_option "function" "(( \$# <= 9 ))" ["\$*"]
# function: A string to identify the source of the call, usually the function name.
# (( \$# <= 9 )): How many args should there be? If false throw error.
# \$*: Argument list. If next arg starts is -something throw an error.
```

### utl_raise_invalid_arg_option
Raise and error and return true if the provided arg begins with a dash.
```bash
> utl_raise_invalid_arg_option "errorText" "\$*"
# errorText: Error string to include in general error message.
```

### utl_raise_invalid_arg_count
Throw error and return true if expression passed into the function is not true.
```bash
> utl_raise_invalid_arg_count "errorText" "(( \$# == X ))"
# errorText: Error string to include in general error message.
# (( \$# == X )): Test the number of args remaining. If this is not true an error is raised.
```

### utl_raise_dir_not_found
Throw error and return true if the provided directory is not found or executable bit is not set.
```bash
> utl_raise_dir_not_found "directory"
```

### utl_set_version
```bash
> utl_set_version "name" version
# name: A simple string identifying the object to set the version for.
# version: Must be a number.
```

### utl_get_version
Return the version number for an object. 0 is returned if the object is not found.
```bash
> utl_get_version "name"
```

### utl_remove_trailing_blank_lines
Remove trailing blank lines from a file or input stream.
```bash
> utl_remove_trailing_blank_lines ["file"]
# file: Optional file name, otherwise expects input stream from standard input.
# 
# **Example**
# ```
# $ (
# > cat <<EOF
# >
# > A
# > B
# >
# > EOF
# > ) | utl_remove_trailing_blank_lines
# 
# A
# B
# 
# ```
```

### utl_first_unblank_line
Return the first unblank line in a file or input stream.
```bash
> utl_first_unblank_line ["file"]
# file: Optional file name, otherwise expects input stream from standard input.
```

### utl_remove_blank_lines
Removes blank lines from a file or input stream.
```bash
> utl_remove_blank_lines [-stdin|"file_path"]
# -stdin: Reads input from standard in.
# file_path: Path to file.
# 
# **Example**
# ```bash
# cat /tmp/example.txt | utl_remove_blank_lines -stdin
# ```
```

### utl_found_in_path_def
Return true if value is not defined as part of ${PATH}.
```bash
> utl_found_in_path_def "directory")
```

### is_not_defined
Return true if provided variable is not defined.
```bash
> is_not_defined "variable"
# variable: Variable to check.
# 
# **Example**
# ```
# $ foo=
# $ is_not_defined "${foo}" && echo "OK" || echo "Not Defined"
# OK
# ```
```

### is_defined
Return true if provided variable is defined.
```bash
> is_defined "X"
# X: Variable to check.
# 
# **Example**
# ```
# $ foo=
# $ is_defined "${foo}" && echo "OK" || echo "Not Defined"
# Not Defined
# ```
```

### get_shell_type
Determine if current shell is bash or ksh.
```bash
> get_shell_type
```

### is_linux
Return true if current OS is Linux.
```bash
> is_linux
```

### is_email_address
Return true if provided string contains an @ and is therefore likely an email address.
```bash
> is_email_address "emailAddressStringToCheck"
```

### utl_to_stderr
Write a text string to standard error.
```bash
> utl_to_stderr "textString"
```

### is_truthy
Return true if value is truthy.
Truthy values are true cron expressions, 1, y, yes, t, true. Upper or lower-case.
```bash
> is_truthy "truthyValue"|"cronExpression"
```

### mktempf
Return path to a newly created temp file.
```bash
> mktempf ["string"]
# string: A string which can be used to identify the source of the file.
```

### rmtempf
Deletes any temp files this session has created. If ```string``` is provided, deletes are limited to matching files.
```bash
> rmtempf "string"
# string: A string to easily identify a group of tmp files.
```

### mktempd
Returns the path to a new temporary directory.
```bash
> mktempd
```

### rmtempd
A safe way to delete a directory created with mktempd.
```bash
> rmtempd "directory"
```

