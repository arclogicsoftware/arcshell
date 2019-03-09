
> Note: Some basic design decisions here are derived from logsna Python library created by Ruslan Spivak. 
> https://github.com/rspivak/logsna

## Features
* Enable debug globally or at the process level.
* Integrates with the Arclogic unit test library.
* In addition to regular log files direct debug to standard error or standard out.

## Get Started
To use the debug library source it into your script or shell. Sourcing in the debug.sh library, a few ways.
```
# Only works if file is in current ${PATH} or "." is in current ${PATH}.
. debug.sh

# Only works if file is in current directory.
# . ./debug.sh

# Full path can present issues porting to other hosts if paths are not the same.
# . /home/arcshell/core/debug.sh
```
Let's make some debug calls. 
```
# Setting a variable up for the example call below.
$ RESUME_NAME="John Doe" 

# Set the _g_debug_level to 3 so all of our statements are actually captured.
$ export _g_debug_level=3

# My preference for debug1 calls is to try to limit them to plain english.
$ debug1 "Processing resumes for external applicants."

# My preference for debug2 calls is to provide function names and input parms.
$ debug2 "process_external_applicant_resumes: "

# My preference for debug3 is to provide more detail. These are usually only
# created when I am troubleshooting and often removed later.
$ debug3 "RESUME_NAME=${RESUME_NAME}" 

# We can show the last 3 lines from the debug log with this command.
$ debug_get 3
DEBUG1   [2017-02-27 08:35:08] 24037: Processing resumes for external applicants.
DEBUG2   [2017-02-27 08:35:11] 24037: process_external_applicant_resumes: 
DEBUG3   [2017-02-27 08:35:14] 24037: RESUME_NAME=John Doe
```
Sometimes it is helpful to see our debug output more immediatly. In addition to logging our debug statements we can redirect them to standard out or standard error using the variable shown here.
```
# 0 log file only, 1 +standard out, 2 +standard error.
$ export _g_debug_output=2
$ debug1 "This line will be returned to the screen via standard error."
DEBUG1   [2017-02-27 08:42:39] 24037: This line will be returned to the screen via standard error.
```
Let's look at the debugd* calls which are meant for supplementary details.
```
$ (echo "Hello World";date;echo "Goodbye") | debugd1
! Hello World
! Mon Feb 27 08:45:01 CST 2017
! Goodbye
```
All detailed calls read standard input and log it to the log file (or screen in this case) with a "!" beginning each line. This allows you to capture larger quantities of debug details, like file or directory contents, or the output from the "set" command. 

Debug can be enabled at the session level using the debug_start call. Below we will reset our global debug settings and then enable a debug session.
```
# Make sure debug calls are not returned to standard out or error in the future.
$ export _g_debug_output=0

# Turn off global debug, although it could be left on.
$ export _g_debug_level=0   

# Start a debug session at level 3.
$ debug_start 3

# Make some debug calls.
$ debug1 "temp=73"
$ debug1 "temp=74"

# Dump the debug buffer to standard out.
$ debug_dump
DEBUG1   [2017-02-27 09:10:43] 24037: temp=73
DEBUG1   [2017-02-27 09:10:52] 24037: temp=74

# Try to dump the buffer again and we can see it is empty until we make more calls.
$ debug_dump
```

## Reference


### debug_show
Return status details about current debug settings.
```bash
> debug_show
```

### debug_follow
Tail the debug log as a background process. 'fg' to bring to foreground.
```bash
> debug_follow
```

### debug_set_level
Set the debug level, 0 to 3.
```bash
> debug_set_level X
```

### debug_set_log
Set the debug log file.
```bash
> debug_set_log "file"
```

### debug_set_output
Set the debug output location. 0 - File, 1 - STDOUT, 2 - STDERR.
```bash
> debug_set_output X
```

### debug_truncate
Truncates the debug log file, primarily used during unit testing and development.
```bash
> debug_truncate
```

### debug_start
Begin a new debug session for the current process.
```bash
> debug_start [debug_level]
# debug_level: Set the session debug level, 1-3. Default is 3.
```

### debug_dump
Dump stored debug calls to standard output as reset the storage file.
```bash
> debug_dump [-x]
# -x: Prevents log file from being truncated/removed subsequent to this call.
```

### debug_stop
End the current debug session and remove buffered lines from the session debug file.
```bash
> debug_stop
```

### debug0
Level 0 debug call. These are logged even if debug is not enabled.
```bash
> debug0 "str"
```

### debug1
Level 1 debug call.
```bash
> debug1 "X"
```

### debug2
Level 2 debug call.
```bash
> debug2 "X"
```

### debug3
Level 3 debug call.
```bash
> debug3 "X"
```

### debugd0
Level 0 "detail" debug call. Reads from standard input.
```bash
> debugd0 ["X"]
```

### debugd1
Level 1 "detail" debug call. Reads from standard input.
```bash
> debugd1 ["X"]
```

### debugd2
Level 2 "detail" debug call. Reads from standard input.
```bash
> debugd2 ["X"]
```

### debugd3
Level 3 "detail" debug call. Reads from standard input.
```bash
> debugd3 ["X"]
```

### debug_get
Return last ```X``` lines from the ```_g_debug_file```.
```bash
> debug_get [X]
# X: Number of lines to return. Defaults to 100.
```

### debug4

### debug5

### debug6

### debugd4

### debugd5

### debugd6

