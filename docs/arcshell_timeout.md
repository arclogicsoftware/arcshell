# arcshell_timeout.sh



## Reference


### timeout_set_timer
Create a new timeout timer.
```bash
> timeout_set_timer "timerKey" [timerSeconds=60]
# timerKey: Key string used to identify timer.
# timerSeconds: Number of seconds on the timer.
```

### timeout_delete_timer
Delete a timer.
```bash
> timeout_delete_timer "timerKey"
```

### timeout_exists
Return true if the timer exists.
```bash
> timeout_exists "timerKey"
```

