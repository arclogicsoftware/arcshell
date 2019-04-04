> All problems in computer science can be solved with another level of indirection. -- David Wheeler

# Flags

**Simple way to set and retrieve a keyed value.**

## Example(s)
```bash

   # Set a flag.
   flag_set "status" "active"
   # Check to see if the flag exists.
   if flag_exists "status"; then
      echo "The 'status' flag exists."
   fi
   # Get the value of a flag.
   if [[ "$(flag_get 'status')" == "active" ]]; then
      flag_set "status" "inactive"
   fi
   # Unset (remove) the flag.
   flag_unset "status"
```

## Reference


### flag_set
Sets the named flag to the value you specify.
```bash
> flag_set "flag_name" "flag_value"
```

### flag_get
Returns the value of the flag. If not set returns nothing.
```bash
> flag_get "flag_name"
```

### flag_exists
Returns true if the flag exists.
```bash
> flag_exists "flag_name"
```

### flag_unset
Unsets the flag.
```bash
> flag_unset "flag_name"
```

