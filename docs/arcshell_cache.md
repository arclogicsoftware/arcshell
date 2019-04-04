# Caching

> If you want to set off and go develop some grand new thing, you don't need millions of dollars of capitalization. You need enough pizza and Diet Coke to stick in your refrigerator, a cheap PC to work on and the dedication to go through with it. -- John Carmack

**A simple yet powerful key value data store.**

Use this module to cache values. You can store single values, single lines, or multiple lines.

Values can be stored by group and key. Keys can then be iterated through by group if needed.

Values can be set to terminate automatically from cache after a specified interval (in seconds).

When retrieving values you have the ability to specify a default return value if a value is not found in cache.

Values can be deleted from cache individually or as a group.

All of this makes caching and retrieving values very easy to implement and maintain.

## Example(s)
```bash

   # Cache a value for 'city'.
   cache_save "city" "Nashville"
   # Get the value of 'city'.
   x="$(cache_get "city")"
   echo "City is ${x}."
```

## Reference


### cache_save
Saves a value to cache.
```bash
> cache_save [-stdin] [-term,-t X] [-group,-g "X"] "cache_key" ["cache_value"]
# -stdin: Use standard input to read the cache value(s). Multiple lines are supported.
# -term: Number of seconds the value is available for.
# -group: Cache group. Defaults to 'default'.
# cache_key: A unique key string used to identify the item within a group.
# cache_value: Value to cache.
```

### cache_get
Gets a value from cache.
```bash
> cache_get [-default,-d "X"] [-group,-g "X"] "cache_key"
# -default: Returns this default value if item is not in cache.
```

### cache_list_keys
List the keys for a set of items in cache.
```bash
> cache_list_keys [-group,-g "X" | cache_group]
```

### cache_exists
Returns true if a value exists in cache.
```bash
> cache_exists [-group,-g "X"] "cache_key"
```

### cache_delete
Deletes a cache entry.
```bash
> cache_delete [-group,-g "X"] "cache_key"
```

### cache_delete_group
Deletes a group of values from cache.
```bash
> cache_delete_group "cache_group"
```

