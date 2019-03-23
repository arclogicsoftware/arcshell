# arcshell_os.sh



## Reference


### os_return_process_cpu_seconds
Returns a record for each process and converts '0-00:00:00' cpu time to seconds.
```bash
> os_return_process_cpu_seconds
```

### os_spawn_busy_process
Spawns busy process N seconds and returns the internal loop count. Breaks if loop count exceeds 10,000.
```bash
> os_spawn_busy_process "seconds"
# seconds: The number of seconds to run for.
```

### os_return_cpu_pct_used
Returns current CPU usage.
```bash
> os_return_cpu_pct_used
```

### os_return_total_cpu_seconds
Attempts to total up the number of CPU seconds elapsed across all running processes.
```bash
> os_return_total_cpu_seconds
```

### os_return_vmstat
Returns results from vmstat in a "metric|value".
```bash
> os_return_vmstat [X=10]
# X: Number of seconds to sample vmstat for at 2 intervals.
```

### os_return_load
Return the OS load using the uptime command as a whole number or decimal.
```bash
> os_return_load [-w]
# -w: Return a whole number.
```

### os_return_os_type
Return short hostname in upper-case.
```bash
> os_return_os_type
```

### os_disks
Return the list of disks available.
```bash
> os_disks
```

### os_is_process_id_process_name_running
Return true if a process ID is running. Checks using process ID alone, or by ID and regular expression.
```bash
> os_is_process_id_process_name_running "processId" ["regex"]
# processId: Unix process ID we are looking for.
# regex: Regular expression used to match the line returned by 'ps -ef'.
```

### os_get_process_count
Return number of processes running which match the provided regular expressions.
```bash
> os_get_process_count "${regex}"
# regex: Regular expression to match to returned 'ps -ef' lines.
# *Example*
# ```
# n=$(os_get_process_count ".*smon.*")
# echo "${n} Oracle SMON Processes Found"
# ```
```

### os_create_process
Create one or more temporary idle processes, typically used for integration and testing purposes.
```bash
> os_create_process "process_name" run_seconds instance_count
# process_name: Name of process to create.
# run_seconds: Number of seconds to run process.
# instance_count: Number of instances of process to create.
```

