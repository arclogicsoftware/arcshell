# arcshell_keywords.sh

## Reference


### keyword_raise_not_found
Raise error and return true if the keyword is not found.
```bash
> keyword_raise_not_found "keyword"
```

### keyword_does_exist
Return true if the keyword exists.
```bash
> keyword_does_exist
```

### keyword_load
Loads a group into the current shell.
```bash
> eval "$(keyword_load 'keyword')"
```

### keywords_count
Return the number of defined keywords.
```bash
> keywords_count
```

### keywords_list
Return the list of all keywords.
```bash
> keywords_list [-l|-a]
# -l: Long list. Include file path to the keyword configuration file.
# -a: All. List every configuration file for every keyword.
```

