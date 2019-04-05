> There is a great satisfaction in building good tools for other people to use. -- Freeman Dyson

# Watcher

**Watches files, directories, processes and other things.**



## Reference


### watch_file
Watch one or more files or directories for changes.
```bash
> watch_file [-recurse,-r] [-hash,-h] [-LOOK,-L] [-look,-l] [-tags,-t "X,x"] [-include,-i "X"] [-exclude,-e "X"] [-stdin] [-watch "X"] "watch_key" ["file_list"]
# -recurse: Recursively search any directories.
# -hash: Adds sha1 or md5 hash to monitor file changes, tries sha1 first.
# -look: Look. Compare file contents when a change is detected if the file is readable.
# -LOOK: LOOK. **Only** examine the contents for changes, ignore file attributes.
# -tags: Tags. Comma separated list of tags. One word per tag. Spaces will be removed.
# -include: Limit files and directories to those matching this regular expression.
# -exclude: Exclude files and directories that match this regular expression.
# -stdin: Read files and directories from standard input.
# -watch: Name of a "file_list" config file which returns the list of files and directories to watch.
# watch_key: A unique string used to identify this particular watch.
# file_list: Comma separated list of files and/or directories.
```

### watch_file_errors
Return the last set of errors encoutered while running watch_file.
```bash
> watch_file_errors
```

### watch_file_delete
Delete all of the cached data assocated with a watch_file key.
```bash
> watch_file_delete "watch_key"
```

