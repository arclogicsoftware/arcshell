A fast counter mechanism for instrumenting code and applications.

## Get Started

```
# Let's start with a clean slate.
counters_delete_group "foo"

# Create a new counter called 'sheep' in foo group.
counters_set "foo,sheep,+1"

# Increment the counter by 1.
counters_set "foo,sheep,+1"

# Value is not updated until 'counters_update' is called.
counters_get "foo,sheep"
0

# Turn off safe mode for the sake of the examples below or we would
# need to wait up to a minute between commands to ensure the "hot"
# file is not longer "hot".
_g_counterSafeMode=0

# This "counts" all counters.  
# counters_update

# Set the counter to ten.
counters_set "foo,sheep,=10"

# Force update and check value.
counters_update
counters_get "foo,sheep"
10

# Let's add an animal to the group.
counters_set "foo,cow,=3"

# Subtract a cow.
counters_set "foo,cow,-1"

# Return all counter values in the group.
counters_update
counters_get "foo"
sheep=10
cow=2

counters_delete_group "foo"
counters_get_group "foo"

# Zero is returned when a counter does not exist.
counters_get "animals,horses"
> 0
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

