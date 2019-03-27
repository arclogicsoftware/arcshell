# Logging

**Logs stuff.**

OK, anyone can write a logger, I know. But this one is special. 

First of all there are commands like```log_help```,  ```log_show```, ```log_follow```, ```log_open```, ```log_get```, and  ```log_quit```.  These commands are going to make your life easier. They are documented below.

Most of the entry points here are capable of logging to standard out or standard error in addition to logging to the  specified log file. This is helpful for example when you trap an error and want to both write it to the log and return the same logged entry to standard error. 

```log_terminal``` is capable of determining if the code it operating from a terminal device and provide feedback otherwise simply log the action to the log without returning the entry to standard output. 

You can optionally log details with a log entry by using the ```-stdin``` option. The log entry is only written if data actually exists on standard input. This enables you to write simple conditional log entries using a single line of code. If you want to log the entry anyway just add the ```-force``` option.

The default log file is ```${arcUserHome}/logs/arcshell.log```.

All in all this is a very capable logger. It used throughout ArcShell and you can use it for your solutions too.



## Reference


### log_set_default
Set all settings back to default values.
```bash
> log_set_default
```

### log_show
Returns current coniguration settings.
```bash
> log_show
```

### log_set_output
Sets the log output targets for the current session.
```bash
> log_set_output [-0] [-1|-2]
# -0: Log to log file.
# -1: Log to standard out.
# -2: Log to standard error.
```

### log_set_file
Set the file being logged to a non-default file.
```bash
> log_set_file "file"
# file: Path to file you want to begin logging to.
```

### log_follow
Tail the arcshell application log as a background process. 'fg' to bring to foreground.
```bash
> log_follow
```

### log_quit
Kills the "log_follow" process if it is running. Doesn't always work but it tries.
```bash
> log_quit
```

### log_open
Open ArcShell application log file in the default editor.
```bash
> log_open
```

### log_terminal
Return text to standard out if the call is originating from a terminal.
> Note: Terminal is zero in a Bash sub-shell even if the code is invoked from a terminal.
```bash
> log_terminal "log_text"
# log_text: The text to log.
# __logging_disable_terminal_log_entries: Set to truthy value to disable writing these values to the log file.
```

### log_boring
Log "boring" text to the application log file.
```bash
> log_boring [-stdin] [-1|-2] [-force,-f] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
# -stdin: Read standard input and log it as a detail entry. Entry is not logged if there is no input.
# -1: Data is returned to standard out in addition to being logged.
# -2: Data is returned to standard error in addition to being logged.
# -force: Forces log write when -stdin is used and no input is found.
# -logkey: A key to identify the primary source of the log entry.
# -tags: Tag list.
# log_text: Text to log.
```

### log_info
Log informational text to the application log file.
```bash
> log_info [-stdin] [-1|-2] [-force,-f] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
# -stdin: Read standard input and log it as a detail entry. Entry is not logged if there is no input.
# -force: Forces log write when -stdin is used and no input is found.
# -1: Data is returned to standard out in addition to being logged.
# -2: Data is returned to standard error in addition to being logged.
# -logkey: A key to identify the primary source of the log entry.
# -tags: Tag list.
# log_text: Text to log.
```

### log_notice
Log a 'NOTICE' to the current log file.
```bash
> log_notice [-stdin] [-1|-2] [-force,-f] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
# -stdin: Read standard input and log it as a detail entry. Entry is not logged if there is no input.
# -1: Data is returned to standard out in addition to being logged.
# -2: Data is returned to standard error in addition to being logged.
# -force: Forces log write when -stdin is used and no input is found.
# -logkey: A key to identify the primary source of the log entry.
# -tags: Tag list.
# log_text: Text to log.
```

### log_event
Log a 'EVENT' record to the current log file.
```bash
> log_event [-stdin] [-1|-2] [-force,-f] [-tags,-t "X,x"] "log_text"
# -stdin: Read standard input and log it as a detail entry. Entry is not logged if there is no input.
# -1: Data is returned to standard out in addition to being logged.
# -2: Data is returned to standard error in addition to being logged.
# -force: Forces log write when -stdin is used and no input is found.
# -logkey: A key to identify the primary source of the log entry.
# -tags: Tag list.
# log_text: Text to log.
```

### log_data
Log a 'DATA' record to the current log file.
```bash
> log_data [-stdin] [-1|-2] [-force,-f] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
# -stdin: Read standard input and log it as a detail entry. Entry is not logged if there is no input.
# -1: Data is returned to standard out in addition to being logged.
# -2: Data is returned to standard error in addition to being logged.
# -force: Forces log write when -stdin is used and no input is found.
# -logkey: A key to identify the primary source of the log entry.
# -tags: Tag list.
# log_text: Text to log.
```

### log_message
Log a 'MESSAGE' record to the current log file.
```bash
> log_message [-stdin] [-1|-2] [-force,-f] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
# -stdin: Read standard input and log it as a detail entry. Entry is not logged if there is no input.
# -1: Data is returned to standard out in addition to being logged.
# -2: Data is returned to standard error in addition to being logged.
# -force: Forces log write when -stdin is used and no input is found.
# -logkey: A key to identify the primary source of the log entry.
# -tags: Tag list.
# log_text: Text to log.
```

### log_critical
Log a 'CRITICAL' record to the current log file.
```bash
> log_critical [-stdin] [-1|-2] [-force,-f] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
# -stdin: Read standard input and log it as a detail entry. Entry is not logged if there is no input.
# -1: Data is returned to standard out in addition to being logged.
# -2: Data is returned to standard error in addition to being logged.
# -force: Forces log write when -stdin is used and no input is found.
# -logkey: A key to identify the primary source of the log entry.
# -tags: Tag list.
# log_text: Text to log.
```

### log_warning
Logs a 'WARNING' record to the current log file.
```bash
> log_warning [-stdin] [-1|-2] [-force,-f] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
# -stdin: Read standard input and log it as a detail entry. Entry is not logged if there is no input.
# -1: Data is returned to standard out in addition to being logged.
# -2: Data is returned to standard error in addition to being logged.
# -force: Forces log write when -stdin is used and no input is found.
# -logkey: A key to identify the primary source of the log entry.
# -tags: Tag list.
# log_text: Text to log.
```

### log_error
Log a 'ERROR' record to the current log file.
```bash
> log_error [-stdin] [-1|-2] [-force,-f] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
# -stdin: Read standard input and log it as a detail entry. Entry is not logged if there is no input.
# -1: Data is returned to standard out in addition to being logged.
# -2: Data is returned to standard error in addition to being logged.
# -force: Forces log write when -stdin is used and no input is found.
# -logkey: A key to identify the primary source of the log entry.
# -tags: Tag list.
# log_text: Text to log.
```

### log_fatal
Log a 'FATAL' record to the current log file.
```bash
> log_fatal [-stdin] [-1|-2] [-force,-f] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
# -stdin: Read standard input and log it as a detail entry. Entry is not logged if there is no input.
# -1: Data is returned to standard out in addition to being logged.
# -2: Data is returned to standard error in addition to being logged.
# -force: Forces log write when -stdin is used and no input is found.
# -logkey: A key to identify the primary source of the log entry.
# -tags: Tag list.
# log_text: Text to log.
```

### log_audit
Log a 'AUDIT' record to the current log file.
```bash
> log_audit [-stdin] [-1|-2] [-force,-f] [-logkey,-l "X"] [-tags,-t "X,x"] "log_text"
# -stdin: Read standard input and log it as a detail entry. Entry is not logged if there is no input.
# -1: Data is returned to standard out in addition to being logged.
# -2: Data is returned to standard error in addition to being logged.
# -force: Forces log write when -stdin is used and no input is found.
# -logkey: A key to identify the primary source of the log entry.
# -tags: Tag list.
# log_text: Text to log.
```

### log_detail
Log a set of details to the current log file. Assumes bulk of data is coming from standard input.
```bash
> log_detail [-1|-2]
# -1: Data is returned to standard out in addition to being logged.
# -2: Data is returned to standard error in addition to being logged.
```

### log_truncate
Truncates the current log file.
```bash
> log_truncate
```

### log_get
Return one or more lines from the application log file.
```bash
> log_get [X=1]
# X: Return last X lines from the log file.
```

