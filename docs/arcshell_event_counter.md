# arcshell_event_counter.sh



## Reference


### event_counter_add_event
Records an event in file using the defined prefix and character.
```bash
> event_counter_add_event [-prefix,-p "X"] [group] ["character"]
# -prefix: Events are recorded on a the line defined using the prefix. The default value includes user host, date, and time in hourly format.
# group: Events are recorded in a unique file for each group.
# character: Events are recorded using the specified character.
```

