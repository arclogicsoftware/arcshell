# arcshell_cache.sh

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

