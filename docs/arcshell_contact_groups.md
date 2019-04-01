# Contact Groups
**Manages group membership and the rules used to send messages to the group.**

Contact groups are used to route messages to the right people, at the right time, using the configured means.

In ArcShell messages can be sent to one or more specific contact groups but ArcShell will route messages to any available contact group if one is not specified.

You can use contact groups to implement automated on-call rotations, message buffering, and define windows in which one contact method is preferred over another.

Each group is configured using an ArcShell configuration file.

The delivered configuration files are in ```${arcHome}/config/contact_groups```.

Configure a contact group by adding a file of the same name to ```${arcGlobalHome}/config/contact_groups``` or ```${arcUserHome}/config/contact_groups``` and modifying the desired values. 

New contact groups can be created by adding a file to one of these directories.

ArcShell loads contact groups in top down order. Delivered, global, then user. All identified files will be loaded when a contact group is used in the code base.

**Example of a contact group configuration file.** 

Contact groups configuration files are loaded as shell scripts. You can use shell to conditionally set the values in these files.

```
# ${arcHome}/config/contact_groups/admins.cfg
# (*)='Truthy' value are accepted.

# Comma separate list of email addresses.
# group_emails="${email},${email}"
# group_emails= 

# Comma separate list of SMS email addresses.
# group_texts="${email},${email}"
# group_texts=

# Is this a default group? Defaults to true. (*)
# Default groups are returned when no other group is provided.
# group_default_group=

# Is this group enabled? Defaults to true. (*)
# group_enabled=

# Is this group disabled? Defaults to false. (*)
# group_disabled=

# Disable SMS texts? Defaults to false. (*)
# group_disable_texts= 

# -----------------------------------------------------------------------------
# Message Queueing/Digest Delivery Settings
# -----------------------------------------------------------------------------

# Is this group on hold? Defaults to false. (*)
# group_hold=

# Message queueing (or digest delivery) is disabled unless one of 
# the values below is set. Queueing can be bypassed when using
# 'send_message' by using the '-now' option.

# Send queued emails if oldest item in queue is older than X seconds.
# group_max_email_queue_seconds=

# Send queued emails if queue has been idle for X seconds.
# group_max_email_queue_idle_seconds=

# Send queued emails if number of items in queue exceeds X.
# group_max_email_queue_count=

# Send queued texts if oldest item in queue is older than X seconds.
# group_max_text_queue_seconds=

# -----------------------------------------------------------------------------
# Slack
#
# Do not uncomment slack settings unless they are being used.
# -----------------------------------------------------------------------------

# Over-rides arcshell.cfg setting.
# arcshell_app_slack_webhook=

# Over-rides keyword configuration setting.
# send_slack=0
```



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

### contact_group_delete
Delete a contact group.
> Make sure you run 'contact_groups_refesh' after deleting one or more groups.
```bash
> contact_group_delete "group_name"
```

