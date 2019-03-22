# ArcShell Scheduler

This module runs scheduled tasks from your scheduled task folders.

## Schedules

To create a schedule create a new directory in one of the 'schedules' folders. This is the name of the schedule. Then add a 'schedule.config' file to configure the schedule.

## Tasks

To create a task just drop an executable file in one of the folders.

## Notes

1) You must load the ArcShell environment in each task file if you are using Korn shell. This is optional with Bash shell. Korn shell does not export the core library functions.
2) Scheduled task files should have unique names.

## Reference


### sch_delete_task
Deletes all matching task files and associated references.
```bash
> sch_delete_task "task_name"
# task_name: Name of task file.
```

### arcshell_check_schedules
Checks schedules and runs tasks. Called by the ArcShell daemon process.
arcshell_check_schedules

### sch_is_task_enabled
Return true if the given task name is both enabled and not disabled.
```bash
> sch_is_task_enabled "task_name"
# task_name: The base name of the task file is the task name.
```

### sch_list_schedules
Returns the list of available schedules.
```bash
> sch_list_schedules [-l]
```

### sch_reset_tasks
Resets all of the enabled/disable settings for the node.
```bash
> sch_reset_tasks
```

### sch_enable_task
Enables a task.
```bash
> sch_enable_task "task_name" ["truthy_value"]
# task_name:
# truthy_value:
```

### sch_disable_task
Disables a task.
```bash
> sch_disable_task "task_name" ["truthy_value"]
# task_name:
# truthy_value:
```

### sch_disable_all_tasks
Disable all tasks.
```bash
> sch_disable_all_tasks
```

### sch_enable_all_tasks
Enable all tasks.
```bash
> sch_enable_all_tasks
```

### sch_does_task_exist
Return true if the task name exists.
```bash
> sch_does_task_exist "task_name"
# task_name: Base name of task file.
```

### sch_list_tasks
Returns a list of the unique task names.
```bash
> sch_list_tasks
```

