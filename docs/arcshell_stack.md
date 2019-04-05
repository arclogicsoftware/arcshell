> When you don't create things, you become defined by your tastes rather than ability. Your tastes only narrow & exclude people. So create. -- Why The Lucky Stiff

# Data Stacks

**Create and manage small data stacks which operate a little like arrays.**



## Reference


### stack_create
Create a new stack if it does not exist.
```bash
> stack_create "stack_name"
```

### stack_add
Add one or more values to the stack.
- Stack is created if it doesn't exist.
- Function can read multiple values from standard input.
```bash
> stack_add [-stdin] "stack_name" ["stack_value"]
```

### stack_list
Return the list of values on stack.
```bash
> stack_list "stack_name"
```

### stack_delete
Delete a stack if it exists.
```bash
> stack_delete "stack_name"
```

### stack_copy
Make a copy of a stack.
```bash
> stack_copy "source_stack" "target_stack"
```

### stack_return_last_value
Return the most recent value on the stack.

### stack_remove_last_value
Remove the most recent value on the stack.
```bash
> stack_remove_last_value "stack_name"
```

### stack_return_first_value
Return the oldest value on the stack.

### stack_remove_first_value
Remove the oldest value on the stack.
```bash
> stack_remove_first_value "stack_name"
```

### stack_pop_last_value
Return and then remove the most recent value from the stack.
```bash
> stack_pop_last_value "stack_name"
```

### stack_pop_first_value
Return and then remove the oldest value on the stack.
```bash
> stack_pop_first_value "stack_name"
```

### stack_count
Return the count of items on the stack.

### stack_has_values
Return true if the stack has any values.
```bash
> stack_has_values "stack_name"
```

### stack_exists
Return true if the stack exists.
```bash
> stack_exists "stack_name"
```

### stack_clear
Clear the stack of all values.
```bash
> stack_clear "stack_name"
```

### stack_value_count
Return a count of the number of times a value appears in the stack.
```bash
> stack_value_count "stack_name" "stack_value"
```

