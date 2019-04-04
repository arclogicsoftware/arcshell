> I have not failed. I've just found 10,000 ways that won't work. -- Richard Pattis

# Files

**Simplifies many common file and directory related tasks.**



## Reference


### file_remove_matching_lines_from_file
Remove all matching lines from a file.
```bash
> file_remove_matching_lines_from_file "file_name" "regex"
```

### file_is_binary
Return true if file is binary, false if not.
```bash
> file_is_binary "file"
```

### file_modify_remove_lines
Modifies file by removing matching lines.
file_modify_remove_lines "file" "regex"

### file_is_executable
Return true if a file is executable.
```bash
> file_is_executable "file"
```

### file_get_ext
Return the file extension to the best of our ability.
```bash
> file_get_ext "file"
```

### file_get_file_root_name
Return the file root name (strips path and extension).
```bash
> file_get_file_root_name [-stdin] | "file"
```

### file_raise_file_not_found
Throw file not found error and return true if file is not found.
```bash
> file_raise_file_not_found "file"
```

### file_raise_dir_not_found
Throw error and return true if directory is not found.
```bash
> file_raise_dir_not_found "directory"
```

### file_is_dir_writable
Return true if a directory is writable.
```bash
> file_is_dir_writable "directory"
```

### file_raise_dir_not_writable
Throw error and return true if directory is not writable.
```bash
> file_raise_dir_not_writable
```

### file_raise_is_not_full_path
Throw error and return true if ```file``` is not the complete path to file.
```bash
> file_raise_is_not_full_path "file"
```

### file_raise_is_path
Throws error and returns true if it appears the file includes the path.
```bash
> file_raise_is_path "file"
```

### file_has_been_modified
Return true if a file has been modified since last time checked. New files return false.
```bash
> file_has_been_modified "file"
```

### file_create_file_of_size
Create a ```file``` of ```bytes```.
```bash
> file_create_file_of_size "file" bytes
```

### file_get_owner
Return the owner of a file. Also reads file names from standard input.
```bash
> file_get_owner "file"
```

### file_join_path
Joins path strings together and returns a single path.
```bash
> file_join_path "string1" "string2" ...
```

### file_line_count
Return the number of lines in a file.
```bash
> file_line_count "file"
```

### file_realpath
Return full path from relative path if possible. Must be able to 'cd' to the dir.
```bash
> file_realpath "file"
```

### file_is_full_path
Return true if the provided file path is full path to the file.
```bash
> file_is_full_path "file"
```

### file_are_files_same
Return true if diff command returns zero lines.
```bash
> file_are_files_same "file1" "file2"
```

### file_modified_time
Returns file modified time in Unix epoch seconds.
```bash
> file_modified_time "file_name"
```

### file_seconds_since_modified
Returns number of seconds since file was last modified.

> Requires perl.

```bash
> file_seconds_since_modified "file_name"
```

### file_is_empty_dir
Return true if directory is empty.
```bash
> file_is_empty_dir "directory"
```

### file_try_mkdir
Try to make a directory and return false if unable.
```bash
> file_try_mkdir "directory"
```

### file_list_files
Return files in a directory. Does not include subdirectories.
```bash
> file_list_files [-l|-a] "directory"
# -l: List full path to file.
# -a: List all attributes.
```

### file_list_dirs
List directory names, not full paths, from specified or current directory.
```bash
> file_list_dirs "directory"
```

### file_is_dir
Return true if the directory exists.
```bash
> file_is_dir "directory"
```

### file_get_dir_kb_size
Returns size of directory contents in kilobytes.

> Errors are suppressed to account for busy directories.
> If you lack correct perms size may not be accurate.

```bash
> file_get_dir_kb_size "directory"
```

### file_get_mb_from_kb
Read kilobytes from input and return megabytes.
```bash
> file_get_mb_from_kb [-stdin]
```

### file_get_dir_mb_size
Get dir size, returns mbytes.
```bash
> file_get_dir_mb_size "directory"
```

### file_get_size
Return file size in bytes.
```bash
> file_get_size "file"
```

### file_get_file_count
Return the number of files from defined or current directory.
```bash
> file_get_file_count "directory"
```

### file_is_empty
Return true if file is zero bytes or contains only blank lines.
```bash
> file_is_empty "file"
```

### file_exists
Return true if file exists.
```bash
> file_exists "file"
```

