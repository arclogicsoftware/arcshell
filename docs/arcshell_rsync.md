# arcshell_rsync.sh

## Reference


### rsync_dir
Sync 'source_dir' to 'target_dir'. 'target_dir' may be created if it does not exist.
```bash
> rsync_dir [-ssh,-s "X"] [-delete,-d] [-exclude,-e "X"] source_dir target_dir
# -ssh: SSH user@hostname, alias, tag, or group.
# -delete: Delete files from target not found in source.
# -exclude: List of files and directories to exclude.
# source_dir: Source directory to sync.
# target_dir: Target directory to sync to. If it does not exist it is created when the parent directory exists already.
```

