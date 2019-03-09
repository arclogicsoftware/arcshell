# arcshell_ssh_connections.sh

## Reference


### ssh_show
Returns the name of the current connection if it has been set..
```bash
> ssh_show
```

### ssh_delete_all_connections
Deletes all connections and rebuilds the local connection.
```bash
> ssh_delete_all_connections
```

### ssh_refresh
Refreshes the ssh connection database. Should be run after modifcations are made.
```bash
> ssh_refresh
```

### ssh_list
Returns the list of ssh connections.
```bash
> ssh_list [-l]
# -l: Long list.
```

### ssh_add
Adds or updates an ssh connection.
```bash
> ssh_add [-port,-p X] [-alias,-a "X"] [-ssh_key,-s "X"] [-tags,-t "X,"] "user@address"
# -port: SSH port number. Defaults to 22.
# -alias: An alternative and usually easy name to recall for this connection.
# -ssh_key: Path to private key file, or file name only if in one of the 'ssh_keys' folders or "\${HOME}/.ssh".
# -tags: Comma separated list of tags. Tags are one word.
# user@address: User name and host name or IP address.
```

### ssh_edit
Edit the specified ssh connection config file. Defaults to local node.
```bash
> ssh_edit ["ssh_connection"]
```

### ssh_delete
Deletes an ssh connection.
```bash
> ssh_delete "ssh_connection"
```

### ssh_set
Sets the current connection.
```bash
> ssh_set "ssh_connection"
# ssh_connection: SSH user@hostname, alias, tag, or group.
```

### ssh_pass_reset
Used to reset the SSHPASS variables.
```bash
> ssh_pass_reset
```

### ssh_unset
Unset the current ssh connection.
```bash
> ssh_unset
```

### ssh_list_groups
List the ssh groups.
```bash
> ssh_list_groups
```

### ssh_list_all_tags
List the ssh tags.
```bash
> ssh_list_all_tags
```

### ssh_list_assigned_tags
Return the list of tags associated with the local node.
```bash
> ssh_list_assigned_tags
```

### ssh_is_tag_assigned
Return true if the local node is associated with the given tag.
```bash
> ssh_is_tag_assigned "tag"
```

### ssh_list_group
Return the list of node names in a group.
```bash
> ssh_list_group "ssh_group"
```

### ssh_list_tag
Return the list of nodes associated with a tag.
```bash
> ssh_list_tag "ssh_tag"
```

### ssh_load
Load the attributes for an ssh node.
```bash
> eval "$(ssh_load "node")"
```

