> There is never enough time to do it right first time, but there is always time to go back and fix it when it breaks. -- Anonymous

# Counters

**A fast counter management mechanism.**

Counters provide you with an easy way to instrument your code with a minimal impact on performance.

Counters are "eventually" consistent. A background process runs every minute and tally's the latest sets of values. 

## Example(s)
```bash


   # Deletes a counter group and all associated files.
   counters_delete_group "foo"

   # Creates a new counter called 'sheep' in the foo group.
   counters_set "foo,sheep,+1"

   # Increments the counter by 1.
   counters_set "foo,sheep,+1"

   # This will return 0. The increment in last step is not
   # available until 'counters_update' is called.
   counters_get "foo,sheep"

   # For examples to return correct values below we need
   # to set this to 0. Normally most recent file is not
   # included in 'counters_update' but when this is 0 it is.
   _g_counterSafeMode=0

   # Set the counter to ten.
   counters_set "foo,sheep,=10"

   # Force update and check value. Will return 10.
   counters_update
   counters_get "foo,sheep"

   # Let's add an animal to the group.
   counters_set "foo,cow,=3"

   # Subtract a cow.
   counters_set "foo,cow,-1"

   # Return all counter values in the group. Returns 10 and 2.
   counters_update
   counters_get "foo"

   counters_delete_group "foo"
   counters_get_group "foo"

   # This returns 0. 0 returned when a counter does not exist.
   counters_get "animals,horses"
```

## Reference


### counters_set
Sets or updates a counter value.
```bash
> counters_set "counter_group,counter_id[,counter_id],[operator]counter_value"
```

### counters_get_group
Return all of the counter values for the group. Format is 'counter=value'.
```bash
> counters_get_group "counter_group"
```

### counters_raise_group_does_not_exist
Return true and error if the counter group does not exist.
```bash
> counters_raise_group_does_not_exist "counter_group"
```

### counters_does_group_exist
Return true if the counter group exists.
```bash
> counters_does_group_exist "counter_group"
```

### counters_get
Return a counter value.
```bash
> counters_get "counter_group,counter"
# counter_group: Counter group.
# counter: A counter within the group.
```

### counters_delete_group
Remove a counter group.
```bash
> counters_delete_group "counter_group"
# counter_group: Counter group.
```

### counters_update
Update all pending counters by processing the .tmp files containing counter data.
```bash
> counters_update
```

### counters_force_update

