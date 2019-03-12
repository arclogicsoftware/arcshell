# arcshell_stats.sh

Statistics storage engine with aggregation and calculation capabilities.

## Reference


### stats_read
Read metrics from standard input and queue for processing. Required input format is "metric|value".
```bash
> stats_read [-s|-m|-h|-v] [-1] [-donottrack,-x] [-tags,-t "X,x"] "stat_group"
# -tags,-t: Tag list.
# -second,-s: Calculate rate per second.
# -minute,-m: Calculate rate per minute.
# -hour,-h: Calculate rate per hour.
# -delta,-v: Calculate the delta.
# -1: Return results to standard out.
# -donottrack,-x: Do not track history.
```

### stat_groups_list
Return the list of all stat groups.
```bash
> stat_groups_list [-l|-a]
# -l: Long list. Include file path to the keyword configuration file.
# -a: All. List every configuration file for every keyword.
```

### stat_group_delete
Delete a stats group.
```bash
> stat_group_delete "stat_group"
```

