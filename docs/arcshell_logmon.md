## Log Monitoring

This short code block shows how easy it is to monitor logs with 
ArcShell. New lines are read from the file using **logmon_read_log**
and piped to a handler called **var_log_messages**. Notifications and
other actions are configured within the handler.

```bash
logmon_read_log -max 10 "/var/log/messages" | \
   logmon_handle_log -stdin "var_log_messages"
```



## Reference


### logmon_register_file
Copies the contents of 'file_name' to the zero buffer. Used for testing.
```bash
> logmon_register_file "file_name"
```

### logmon_cat
Returns the specified buffer to standard out.
```bash
> logmon_cat [-from,-f "X"]
```

### logmon_append
Appends matching lines from one buffer to another.
```bash
> logmon_append [-ignore_case,-i] [-from,-f "X"] -to,-t "X" ["regex"]
# -ignore_case:
# -from: From buffer id.
# -to: To buffer id.
# regex:
```

### logmon_reset
Removes all buffer files and resets a couple of global variables.
```bash
> logmon_reset
```

### logmon_read_log
This function is used to intermittently check files for new lines and return only those lines.
```bash
> logmon_read_log [-new,-n] [-max,-m X] "filePath"
# -new: If file is new existing lines are treated as new lines.
# -max: Limit amount of data that can be returned to X megabytes. Defaults to 10.
```

### logmon_handle_log
Process input and scan it using a log handler.
```bash
> logmon_handle_log [-stdin] [-meta "X"] ["source_file"] "log_handler"
# -stdin: Read log input from standard in.
# -meta: Sets the meta value which can be referenced in the handler.
# source_file: Source file containing the data we want to scan.
# log_handler: The name of a log handler.
```

### logmon_extract
Remove matching lines from a buffer and return to standard out or copy to a new buffer.
```bash
> logmon_extract [-ignore_case, -i] [-from,-f "X"] [-to,-t "X"] ["regex"]
# -ignore_case: Ignore case.
# -from: Buffer id to extract lines from. Defaults to buffer "0".
# -to: Buffer id to copy extracted lines to. Defaults to standard out.
# regex: Regular expression used to identify extracted lines. Defaults to all lines.
```

### logmon_grep
Returns matching lines to standard out.
```bash
> logmon_grep [-ignore_case, -i] [-from,-f "X"] ["regex"]
# -ignore_case: Ignore case.
# -from: Buffer id to extract lines from.
# regex:
```

### logmon_write
Used in a handler to write standard input to the specified buffer.
```bash
> logmon_write [-buffer,-b "X"] [buffer_id]
# -buffer: The buffer number to write to.
# buffer_id: Also the buffer number to write to.
```

### logmon_remove
Used in a handler to remove matching lines from the specified buffer.
```bash
> logmon_remove [-ignore_case,-i] [-from,-f "X"] ["regex"]
# -ignore_case: Ignore case.
# -from: Buffer id to remove lines from.
# regex: Regular expression. Defaults to all lines.
```

### logmon_meta_value
Used in a handler to return the value of the '-meta' argument.
```bash
> logmon_meta_value
```

### logmon_forget_file
Remove the object library reference to a file.
```bash
> logmon_forget_file "filePath"
```

