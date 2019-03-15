# arcshell_threshold_monitor.sh

## Reference


### threshold_monitor
Monitors input for defined thresholds.
```bash
> threshold_monitor [-stdin] [-t1,-t2,-t3 "threshold,duration,['keyword']]" [-config "X"] "threshold_group"
# -t[1-3]: Threshold, duration (min), and optional keyword.
# -config: Threshold configuration file. Works with ArcShell config or fixed path.
# threshold_group: Each set of data piped to this function should be identified as a unique group.
```

