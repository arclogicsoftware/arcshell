> "Weeks of coding can save you hours of planning." - Anonymous

# Timer

**Create and manage timers for timing all kinds of things.**

## Example(s)
```bash

   # Create the timer and start it.
   timer_create -force -start "foo"
   # Do something for 5 seconds.
   sleep 5
   # Should return 5.
   timer_seconds "foo"
   # Do something for 55 seconds.
   sleep 55
   # Should return 1.
   timer_minutes "foo"
   # Stop the timer.
   timer_stop "foo"
   # Starts the timer counting from the point it was stopped at.
   timer_start "foo"
   # End the timer.
   timer_end "foo"
```

## Reference


### timer_mins_expired
Returns true when timer interval has passed and resets the timer.
```bash
> timer_mins_expired [-inittrue,-i] "timerKey" minutes
# -inittrue: Forces return of true the first time the timer is created.
# timerKey: A unique key used to identify the timer.
# minutes: The number of minutes to wait before expiring and returning true.
# **Example**
# ```
# timer_mins_expired "timerX" 1 && echo Yes || echo No
# ```
```

### timer_secs_expired
Returns true when timer interval has passed and resets the timer.
```bash
> timer_secs_expired [-inittrue,-i] "timerKey" seconds
# -inittrue: Forces return of true the first time the timer is created.
# timerKey: A unique key used to identify the timer.
# seconds: The number of seconds to wait before expiring and returning true.
# **Example**
# ```
# timer_secs_expired "timerX" 10 && echo Yes || echo No
# ```
```

### timer_create
Create a new timer. Throws an error if it already exists.
```bash
> timer_create [-force,-f] [-start,-s] [-autolog,-a] ["timerKey"]
# -force: Re-create the timer if it already exists.
# -start: Start timer automatically.
# -autolog: Logs timer automatically.
# timerKey: Unique key assigned to the timer. Defaults to current process ID.
```

### timer_time
Starts a new timer which will be auto-logged when timer_end if called.
```bash
> timer_time ["timerKey"]
```

### timer_end
Used to stop timing a timer started with timer_time.
```bash
> timer_end ["timerKey"]
```

### timer_start
Start a new timer or restart an existing timer.
```bash
> timer_start "timerKey"
```

### timer_seconds
Return current timer time in seconds. Auto create and start if it doesn't exist.
```bash
> timer_seconds ["timerKey"]
```

### timer_minutes
Return current timer time in minutes. Auto create and start if it doesn't exist.
```bash
> timer_minutes ["timerKey"]
```

### timer_log_timer
Logs the current timer time to the application log.
```bash
> timer_log_timer ["timerKey='$$']
```

### timer_reset
Reset a timer, also starts it if it is not running already.
```bash
> timer_reset ["timerKey"]
```

### timer_stop
Stop a timer.
```bash
> timer_stop "timerKey"
```

### timer_delete
Delete a timer.
```bash
> timer_delete "timerKey"
```

### timer_exists
Return true if timer exists.
```bash
> timer_exists "timerKey"
```

