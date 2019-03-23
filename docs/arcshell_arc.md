This module provides users with the ability to install, package, update, uninstall, and run commands on other ArcShell nodes over SSH. 

There are other helpful commands which can be used when building your own modules for ArcShell. Please see the documentation for each function below.

## Reference


### arc_menu
Runs the ArcShell main menu.
```bash
> arc_menu
```

### arc_version
Returns the current version of ArcShell.
```bash
> arc_version [-n]
# -n: Returns the version as a real number instead of a string.
```

### arc_install
Install ArcShell on one or more remote nodes over SSH.
```bash
> arc_install [-force,-f] [-arcshell_home,-a "X"] [-ssh "X"] ["package_path"]
# -force: Install ArcShell even if it is already installed.
# -arcshell_home: Directory which will be the "${arcHome}" on the node.
# -ssh: SSH user@hostname, alias, tag, or group.
# package_path: Path to ArcShell package file. Not required if the working package file is set.
```

### arc_update
Update remote or local ArcShell installation using an ArcShell package file.
```bash
> arc_update [-ssh "X"] ["package_path"]
# -ssh: SSH user@hostname, alias, tag, or group.
# package_path: Path to ArcShell package file. Not required if the working package file is set.
```

### arc_sync
Uses 'rsync' to sync the current ArcShell home to a remote ArcShell home.
```bash
> arc_sync [-ssh "ssh_connection"] [-setup,-s] [-delete,-d]
# -ssh: SSH user@hostname, alias, tag, or group.
# -setup: Run 'arcshell_setup.sh' after syncing.
# -delete: Delete remote files if not found locally.
```

### arc_uninstall
Remove ArcShell from a remote node.
```bash
> arc_uninstall [-ssh "X"]
```

### arc_is_daemon_suspended
Returns true if the daemon process is suspended.
```bash
> arc_is_daemon_suspended
```

### arc_is_daemon_running
Return true if the ArcShell daemon process appears to be alive.
```bash
> arc_is_daemon_running
```

### arc_show
Returns information about the current environment.
```bash
> arc_show
```

### arc_run_cmd
Run a command on a remote node within the remote ArcShell environment.
```bash
> arc_run_cmd [-ssh "X"] [-local,-l] "command"
# -ssh: SSH user@hostname, alias, tag, or group.
# command: The command to run.
```

### arc_pkg
Package ArcShell and save it to the user or global packages configuration folder.
```bash
> arc_pkg [-global,-g|-local,-l] ["package_name"]
# -global: Create a global package instead of local.
# -local: Create a local package (default).
# package_name: Package name. Defaults to "ArcShell_" with a datetime string.
```

### arc_secure_home
Secure file and directory permissions in ArcShell directories.
```bash
> arc_secure_home
```

