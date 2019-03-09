## sudo.sh

## User Reference
----

### sudo_update
Fetch the list of available updates.
```c
> sudo_update
```

### sudo_upgrade
Update current packages.
```c
> sudo_upgrade
```

### sudo_dist_upgrade
Install new packages.
```c
> sudo_dist_upgrade
```

### sudo_update_all
Updates and installs current packages as well as installs new ones.
```c
> sudo_update_all
```

### sudo_create_user
Create a user and home directory if the user does not already exist.
```c
> sudo_create_user "user" ["pass"] ["shell"]
```

### sudo_delete_user
Delete a Linux/Unix user account and home directory.
```c
> sudo_delete_user "user"
```

### sudo_does_user_exist
Return true if user exists.
sudo_does_user_exist "user"

### sudo_set_pass
Set the password for a user. Should be changed right away, this is only for testing.
sudo_set_pass "user" "pass"

## Developer Reference
----

### _sudoThrowError
Return error message to standard error.
```c
> _sudoThrowError "error_message"
```

