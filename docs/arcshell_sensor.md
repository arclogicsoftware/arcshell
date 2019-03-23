# arcshell_sensor.sh



## Reference


### sensor_check
Return true if a sensor is triggered otherwise return false.
This type of check does not return output.
```bash
> sensor_check [-group,-g "X"] [-try,-t X] [-new,-n] [-tags "X"] [-log,-l] "sensor_key"
# -group: The sensor group.
# -try: Try X times before triggering sensor.
# -new: Detect new input lines only.
# -tags: Comma separated list of tags. One word each. Will be written to log if enabled.
# -log: Logs sensor data when triggered.
# sensor_key: Unique string within a group which identifies a sensor.
```

### sensor
Sensors detect changes in input.
```bash
> sensor [-group,-g "X='default'"] [-try,-t X] [-new,-n] [-tags "X,x"] [-log,-l] "sensor_key"
# -group: The sensor group.
# -try: The number of times to try before triggering a sensor.
# -new: Only new lines are considered when detecting changes.
# -tags: List of tags.
# -log: Log sensor events when triggered.
# sensor_key: Unique string within a group which identifies a sensor.
```

### sensor_exists
Return true if the provided sensor exists.
```bash
> sensor_exists [-group "X"] "sensor_key"
```

### sensor_return_sensor_value
Return the current value/text stored by the sensor.
```bash
> sensor_return_sensor_value [-group,-g "X"] "sensor_key"
```

### sensor_get_last_diff
Return the diff from last time sensor ran.
```bash
> sensor_get_last_diff [-group,-g "X"] "sensor_key"
```

### sensor_get_sensor_status
Returns last status. Can be one of 'passed', 'failing', 'failed'.
```bash
> sensor_get_sensor_status [-group,-g "X"] "sensor_key"
```

### sensor_delete_sensor
Delete a sensor by key.
```bash
> sensor_delete_sensor [-group,-g "X"] "sensor_key"
```

### sensor_passed
Return true if "sensor_key" passed.
```bash
> sensor_passed [-group,-g "X"] "sensor_key"
```

### sensor_is_failing
Return true if "sensor_key" is failing.
```bash
> sensor_is_failing [-group,-g "X"] "sensor_key"
```

### sensor_failed
Return true if "sensor_key" failed.
```bash
> sensor_failed [-group,-g "X"] "sensor_key"
```

### sensor_delete_sensor_group
Delete all of the sensors in a group.
```bash
> sensor_delete_sensor_group "sensor group"
```

### sensor_get_last_detected_times
Return the last X times the sensor detected a change.
```bash
> sensor_get_last_detected_times [-group,-g "X"] "sensor_key" [X=10]
# group: Sensor group.
# sensor_key: Unique key of the sensor.
# X: Number of records to return.
```

### sensor_get_fail_count
Return the counter value for the sensor fail count.
```bash
> sensor_get_fail_count [-group,-g "X"] "sensor_key"
```

### sensor_list_sensors

```bash
> sensor_list_sensors [-group,-g "X"]
```

