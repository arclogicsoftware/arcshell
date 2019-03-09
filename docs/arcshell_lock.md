# arcshell_lock.sh

## Reference


### lock_aquire
Try to aquire the "lock_id" lock.
```bash
> lock_aquire [-try,-t X] [-term,-t X] [-force,-f] [-error,-e] "lock_id"
# -try: Number of attempts to try to aquire a lock before failing. 1 second between attempts.
# -term: Number of seconds lock is held for before auto expiring.
# -force: Throw error and force aquisition of the lock after waiting if need be.
# -error: Throw error if you fail to aquire the lock.
# lock_id: A unique string to identify the lock.
```

### lock_release
Remove "lock_id" if it exists. No errors if it does not exist.
```bash
> lock_release "lock_id"
```

