# "ARCLOGIC" UTILITIES FOR ORACLE

### INSTALLATION
* Run the arc_user.sql script as SYS and pass in the name of the ARCLOGIC PL/SQL package owner.
* Login as the ARCLOGIC PL/SQL package owner and run arc_install.sql.

### TABLES

> Nothing to see here yet :)!

### VIEWS

**locked_objects**
Returns session level information about current locked objects from GV$LOCKED_OBJECT.

**lockers**
Returns information about lockers and blockers for current Oracle locks.

**lock_time**
Returns the total number of seconds sessions have been holding locks for. This value can be monitored for a threshold which triggers an alarm.

**name_generator**
Uses the Oracle data dictionary to return a random string of three works such as "NETWORK_PLSQL_SQLCOMMAND".

## ARCLOGIC PL/SQL PACKAGE

**secs_between_timestamps**
Returns the number of seconds between two timestamps.
```sql
secs_between_timestamps (time_start in timestamp, time_end in timestamp) return number 
```

---
**secs_since_timestamp** 
Return the number of seconds since a timestamp.
```sql
secs_since_timestamp (time_stamp timestamp) return number
```

---
**str_to_key_str** - Turns any string into a "key" string. 

Replace anything in "str" that is not A-Z, a-z, or 0-9, with under-bar "_".

```sql
str_to_key_str (str in varchar2) return varchar2
```
---

