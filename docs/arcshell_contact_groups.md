## Contact Groups

Use contact groups to...

* Get messages and alerts to the right people.
* At the right time.
* Using the allowed means.

With contact groups you can...

* Direct messages to particular groups.
* Define on-call rotations.
* Implement message queuing and send message digests. 

This is all accomplished by setting up a simple configuration file for each group. 



## Reference


### contact_group_load
Loads a group into the current shell.
```bash
> eval "$(contact_group_load 'group_name')"
```

### contact_group_exists
Return true if the contact group exists.
```bash
> contact_group_exists "group_name"
```

### contact_group_is_enabled
Returns true if group is "enabled" and not "disabled".
```bash
> contact_group_is_enabled "group_name"
```

### contact_groups_enabled_count
Return the number of enabled contact groups.
```bash
> contact_groups_enabled_count
```

### contact_groups_list
Return the list of all groups.
```bash
> contact_groups_list [-l|-a]
# -l: Long list. Include file path to the groups configuration file.
# -a: All. List every configuration file for every group.
```

### contact_groups_list_enabled
Return the list of groups which are currently enabled.
```bash
> contact_groups_list_enabled
```

### contact_groups_list_default
Return a list of the default groups, they are not necessarily enabled.
```bash
> contact_groups_list_default
```

### contact_groups_refresh
Rebuilds objects when a contact group config file has been changed.
```bash
> contact_groups_refresh
```

### contact_group_delete
Delete a contact group.
> Make sure you run 'contact_groups_refesh' after deleting one or more groups.
```bash
> contact_group_delete "group_name"
```

