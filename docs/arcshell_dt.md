# arcshell_dt.sh

## Reference


### dt_return_seconds_since_epoch
Return number of elapsed seconds since the given epoch.
```bash
> dt_return_seconds_since_epoch epoch
```

### dt_return_minutes_since_epoch
Return number of elapsed minutes since the given epoch.
```bash
> dt_return_minutes_since_epoch epoch
```

### dt_date_stamp
Return date string in YYYYMMDD format using defined separator.
dt_date_stamp ["dateSeparator"]
dateSeparator: A string, usually a "-", or "_" used to separate the year, month and day fields.

### dt_seconds_remaining_in_minute
Returns the number of seconds until the top of the next minute.
```bash
> dt_seconds_remaining_in_minute
```

### dt_ymd
Return date in format 'YYYYMMDD', often used as part of a file name.

### dt_ymd_hms
Return date time in 'YYYY-MM-DD_HHMISS' format.
```bash
> dt_ymd_hms
```

### dt_y_m_d_h_m_s
Return date time in 'YYYY_MM_DD_HH_MI_SS' format.
```bash
> dt_y_m_d_h_m_s [delimiter="_"]
```

### dt_y_m_d_h_m
Return date time in 'YYYY_MM_DD_HH_MI' format.
```bash
> dt_y_m_d_h_m [delimiter="_"]
```

### dt_y_m_d_h
Return date time in 'YYYY_MM_DD_HH' format.
```bash
> dt_y_m_d_h [delimiter="_"]
```

### dt_hour
Returns the current hour (0-23) with leading zeros removed.
```bash
> dt_hour
```

### dt_minute
Returns the current minute (0-59) with leading zeros removed.
```bash
> dt_minute
```

### dt_second
Returns the current second (0-59) with leading zeros removed.
```bash
> dt_second
```

### dt_year
Returns the current year.
```bash
> dt_year
```

### dt_day
Return current day of month (1-31) with leading zeros removed.
```bash
> dt_day
```

### dt_month
Return current month (1-12) with leading zeros removed.
```bash
> dt_month
```

### dt_is_weekday
Exit true if current day is a week day.
dt_is_weekday

### dt_is_weekend
Exit true if current day is a week end.
dt_is_weekend

### dt_epoch
Return unit epoch in minutes or seconds.
```bash
> dt_epoch
```

### dt_get_seconds_from_interval_str
Converts the allowable interval styled strings to the equivalent value in seconds.

An interval string looks like this, 1d, 1h, 1m, 1s, where d=day, h=hour, m=minutes, s=seconds. This function converts those values to seconds, so 1h returns 3600.
```bash
> dt_get_seconds_from_interval_str "intervalString"
# **Example**
# ```
# numberOfSeconds=$(dt_get_seconds_from_interval_str "1h")
# echo ${numberOfSeconds}
# 60
# ```
```

### dt_get_duration_from_elapsed_seconds
Takes the number of seconds and returns a formated time string, for example, "10 days, 04:31:23".
dt_get_duration_from_elapsed_seconds X
X: Number of seconds.

