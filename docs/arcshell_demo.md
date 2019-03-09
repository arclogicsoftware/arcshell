# arcshell_demo.sh

## Reference


### demo_end

### demo_return_markdown

### demo_figlet

### demo_get_function_doc
Get doc lines for specified function.
```bash
> demo_get_function_doc "file" "func"
```

### demo_code
Populates the buffer with the code you want to run but does not run it.
```bash
> demo_code [-l] "code_block" [pause_seconds]
# code_block: Block of shell code to prepare to execute.
```

### demo_run
Runs the code in the buffer.
```bash
> demo_run -subshell
# subshell: Runs the command as a sub-process.
```

### demo_key
Display characters on the screen. Simulate typing if key delay is set.
This function reads standard input or \${1} parameter.
```bash
> demo_key "text" [seconds]
# text: Text to key.
# seconds: Number of seconds to sleep at end of command.
```

### demo_wait
Pause demo and wait for user input to continue.
> demo_wait

