# arcshell_ssh.sh



## Reference


### ssh_connect
Connect to a node using SSH.
```bash
> ssh_connect [-ssh "X"|"regex"|?]
# -ssh: SSH user@hostname, alias, tag, or group.
# regex: Returns a menu of matching SSH connections.
# ?: Returns a menu of all SSH connections.
```

### ssh_check
Validate the health of the current ssh connection. Works against local node too.
```bash
> ssh_check [-ssh,-s "X"] [-fix,-f] ["ssh_connection"]
# -fix: Automatically fixes issues.
# ssh_connection: Same as '-ssh'.
```

### ssh_send_key
Copy contents of ~/.ssh/id_rsa.pub to the current connection's authorized keys file.
Note: Function can be run multiple times, key is only added if it is not there.
```bash
> ssh_send_key [-ssh "X"] [-force] ["ssh_connection"]
# -force: Update authorized_keys entry even if key is already in file.
# ssh_connection: Same as '-ssh'.
```

### ssh_get_key
Get contents from remote ~/.ssh/id_rsa.pub and add it to local authorized_keys file.
```bash
> ssh_get_key [-force,-f] [-ssh "X"] ["ssh_connection"]
# -force: Update authorized_keys entry even if key is already in file.
# -ssh: SSH user@hostname, alias, tag, or group.
# ssh_connection: SSH user@hostname, alias, tag, or group.
```

### ssh_swap_keys
Run both ssh_send_key and ssh_get_key.
```bash
> ssh_swap_keys [-force,-f] [-ssh,-s "X"] ["ssh_connection"]
# -force: Update authorized_keys entry even if key is already in files.
# -ssh: SSH user@hostname, alias, tag, or group.
# ssh_connection: SSH user@hostname, alias, tag, or group.
```

### ssh_copy
Copy a file or directory to one or more nodes.
```bash
> ssh_copy [-local,-l] [-ssh,-s "X"] "source_path" ["target_path"]
# -local: Action can be applied locally if it is an included node.
# -ssh: SSH user@hostname, alias, tag, or group.
# source_path: Path to local file or directory to copy.
# target_path: File or directory to copy source_path to. Defaults to user's home.
```

### ssh_run_cmd
Run a command on the targeted nodes.
```bash
> ssh_run_cmd [-local,-l] [-ssh,-s "X"] "command"
# -local: Action can be applied locally if it is an included node.
# -ssh: SSH user@hostname, alias, tag, or group.
# command: The command to run.
```

### ssh_run_file
Run a file on all of the targeted nodes.
```bash
> ssh_run_file [-local,-l] [-ssh,-s "X"] "file_path"
# -local: Action can be applied locally if it is an included node.
# -ssh: SSH user@hostname, alias, tag, or group.
# file_path: Path to local file which will be run against selected nodes.
```

### ssh_does_dir_exist
Return true if a remote directory exists.
```bash
> ssh_does_dir_exist [-ssh "X"] "directory"
# -ssh: SSH user@hostname or alias.
# directory: Full or relative path of directory you want to check for.
```

### ssh_get_home
Return the home directory path for a node or group of nodes.
```bash
> ssh_get_home [-ssh "X"] ["ssh_node_or_alias"]
# -ssh: SSH user@hostname or alias.
# ssh_node_or_alias: SSH user@hostname or alias.
```

### ssh_list_key_types_in_use
Return the list of ssh key types found in the provided directory.
```bash
> ssh_list_key_types_in_use
```

