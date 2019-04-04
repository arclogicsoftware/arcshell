# Threshold Monitor

> There are only two kinds of languages: the ones people complain about and the ones nobody uses. -- Bjarne Stroustrup

**Monitors values based on thresholds combined with time limits.**

## Example(s)
```bash


   # Input can be a one or two fields. Either "metric|value" or just "value".
   # Input can be more than one line.

   # Monitor OS load average with three different thresholds.
   os_return_load | \
      threshold_monitor \
         -t1 "4,12h,warning" \
         -t2 "14,30m,warning" \
         -t3 "20,0m,critical" \
         "os_load"

   # A configuration file can be used instead.
   os_return_load | \
      threshold_monitor -config "os_load.cfg" "os_load"

   # threshold_monitor can be used like this.
   if os_return_load | threshold_monitor -config "os_load.cfg" "os_load"; then
      # Do something here.
      :
   fi
```

## Reference


### threshold_monitor
Monitors input for defined thresholds.
```bash
> threshold_monitor [-stdin] [-t1,-t2,-t3 "threshold,duration,['keyword']]" [-config "X"] "threshold_group"
# -t[1-3]: Threshold, duration (min), and optional keyword.
# -config: Threshold configuration file. Works with ArcShell config or fixed path.
# threshold_group: Each set of data piped to this function should be identified as a unique group.
```

