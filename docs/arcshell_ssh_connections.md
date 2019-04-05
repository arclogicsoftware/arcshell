> That's the thing about people who think they hate computers. What they really hate is lousy programmers. -- Larry Niven 

# SSH Connections

**An SSH connection management module.**

You can save time navigating hosts with SSH and running commands by using this module.

**Features**
* Nodes can be assigned an easy to remember aliases and multiple tags.
* Global connections are available on all ArcShell nodes automatically.
* Dynamic Node Groups 
* Run commands or scripts against one or multiple hosts using aliases, tags, and groups.
* Supports **sshpass** 
* Corrects common SSH key authentication configuration issues.
* Supports use of unique keys.
* Runs on any Unix or Linux host using either the Bash or Korn shell.

 Each connection is created using a simple configuration file in one of these two locations.

```${arcGlobalHome}/config/ssh_connections```
```${arcUserHome}/config/ssh_connections```

If there are two files only one is loaded. The file in the **user** home has precedence. Files in the **global** home are distributed to the other nodes in your network when you deploy ArcShell. 

This is an example of a configuration file.
```
# ${arcHome}/global/config/ssh_connections/ethan@devgame.cfg

# Generated using 'ssh_add'.

# An alias makes it easy to refer to the node.
node_alias="ethan@devgame"

# One or more tags. Use commas between tags.
node_tags=""

# The ssh port to connect to. Defaults to 22 if not provided.
node_port=22

# If Bash or Korn shell is not default shell one of those shells needs to be defined here.
node_shell=

# Private key file path or just the name if it is in your 'ssh_keys' folders.
node_ssh_key=""

# Optionally supply ths SSHPASS value to avoid having to provide it the first time.
node_sshpass=""
```
```ssh_add``` can be used to create connections from the command line or the files can be created manually. Some configuration settings always need to be modified by editing the file directly.

```ssh_refresh``` needs to be executed when a group of changes are complete. This procedure rebuilds the indexes that contain information about the defined tags, aliases, and SSH groups.

```ssh_set``` can be used to set the current SSH connection. It can be set to a specific node, alias, tag, or group. When set you will not need to provide it when running commands.

ArcShell supports SSHPASS if you are on a Linux OS and unable to configure SSH keys. You can set the ```node_sshpass``` value in the configuration file for the node to enable this capability when connecting to the node. The ```sshpass``` program needs to be installed.

SSH groups are created using an SSH group configuration file. 

```${arcGlobalHome}/config/ssh_groups```
```${arcUserHome}/config/ssh_groups```

SSH groups are shell scripts ending in ```.cfg``` which do the following:
* Return a list of nodes, aliases, and tags which comprise the group when executed.
* Does not return group names! You can end up with a recursive operation very easily!
* Returns members of other groups by using the ```ssh_return_nodes_in_group``` function as a work around.



## Reference


### ssh_add
Add or updates an SSH connection.
```bash
> ssh_add [-port,-p X] [-alias,-a "X"] [-ssh_key,-s "X"] [-tags,-t "X,"] "user@address"
# -port: SSH port number. Defaults to 22.
# -alias: An alternative and usually easy name to recall for this connection.
# -ssh_key: Path to private key file, or file name only if in one of the 'ssh_keys' folders or "\${HOME}/.ssh".
# -tags: Comma separated list of tags. Tags are one word.
# user@address: User name and host name or IP address.
```

### ssh_refresh
Refreshes the SSH connection database. Should be run after modifications are made.
> This will eventually get set up as an automated background task but for now you either need to run setup or ssh_refresh after adding/modifying connections.
```bash
> ssh_refresh
```

### ssh_list
Returns the list of SSH connections.
```bash
> ssh_list [-l]
# -l: Long list.
```

### ssh_edit
Edit the specified ssh connection config file. Defaults to local node.
```bash
> ssh_edit ["ssh_connection"]
```

### ssh_set
Sets the current SSH connection. It can be a node, alias, tag, or group.
```bash
> ssh_set "ssh_connection"
# ssh_connection: SSH user@hostname, alias, tag, or group.
```

### ssh_show
Returns the name of the current connection if it has been set. It can be set using ssh_set procedure.
```bash
> ssh_show
```

### ssh_delete
Deletes an SSH connection.
```bash
> ssh_delete "ssh_connection"
```

### ssh_delete_all_connections
Deletes all connections and rebuilds the local connection.
> This can be used if you are rebuilding all of your connections from another source.
```bash
> ssh_delete_all_connections
```

### ssh_unset
Unset the current SSH connection.
```bash
> ssh_unset
```

### ssh_pass_reset
Used to reset the SSHPASS variables.
```bash
> ssh_pass_reset
```

### ssh_return_groups
List the ssh groups.
```bash
> ssh_return_groups
```

### ssh_return_nodes_in_group
Return the list of node names in a group.
```bash
> ssh_return_nodes_in_group "ssh_group"
```

### ssh_return_tags
List the ssh tags.
```bash
> ssh_return_tags
```

### ssh_return_tags_for_this_node
Return the list of tags associated with the local node.
```bash
> ssh_return_tags_for_this_node
```

### ssh_is_tag_assigned_to_this_node
Return true if the local node is associated with the given tag.
```bash
> ssh_is_tag_assigned_to_this_node "tag"
```

### ssh_return_nodes_with_tag
Return the list of nodes associated with a tag.
```bash
> ssh_return_nodes_with_tag "ssh_tag"
```

### ssh_load
Load the attributes for an ssh node.
```bash
> eval "$(ssh_load "node")"
```

