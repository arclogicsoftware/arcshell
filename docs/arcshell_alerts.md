# Alerting

**Easily incorporates recurring alerts and notifications into your scripts.**

Use alerts to set up a recurring notifications until a condition is resolved or the alert cycle completes.

Alerts are opened using an alert type. 

Alert types are found in the ```${arcHome}/config/alert_types``` folder.

To change the settings for an alert type copy the alert type file to the ```${arcGlobalHome}/config/alert_types``` folder or ```${arcUserHome}/config/alert_types``` and modify it. 

Alert types can be created by placing new files in one of these two folders. We recommend keeping the number of alert types to a minimum.

Each alert type allows you to configure two alert windows. The initial window and a reminder window. 

Each window is associated with an ArcShell "keyword", an alert count, and an alert interval.

Alert notifications are sent to the ArcShell messaging system with the associated keyword. Please see the ArcShell **keywords** and **messaging** documentation for more.

The initial alert count defines the number of notifications that  occur before moving to the reminder window. The initial alert interval defines the number of minutes between notifications.

Once the settings for the initial and reminder windows are exhausted the alert is automatically closed. If the condition still exists it will likely be re-opened and the cycle will reiterate. 

Alerts can be closed even if they are not open without effect. This makes coding if then else blocks to open and close alerts easy to implement.

```

   # Source in ArcShell
   . "${HOME}/.arcshell"

   # Open a 'critical' alert if the cron process is not running.
   if (( $(ps -ef | grep "cron" | grep -v "grep" | num_line_count) == 0 )); then
      alert_open -critical "cron_process_alert" "'cron' process is not running!"
   else
      # Automatically closes alert if it has been opened.
      alert_close "cron_process_alert"
   fi

```

**Alert Type Example**

```
# ${arcHome}/config/alert_types/high.cfg
#
# The initial keyword to associate with the alert. 
# It must be one of the configured keywords.
alert_keyword="critical"

# How many times should the initial alert type notify with the above keyword?
alert_count=1

# What is the notification interval in minutes?
alert_interval=

# Once the above completes we can change the keyword.
# It can be less critical or more.
alert_reminder_keyword="warning"

# Reminder count before automatically closing the alert.
alert_reminder_count=999

# Reminder interval in minutes.
alert_reminder_interval=60
```

**Keyword Example**

```
# ${arcHome}/config/keywords/critical.cfg
#
# Truthy values including ArcShell cron expressions are acceptable.
send_text=1
send_email=1
send_slack=0
```

## Reference


### alert_open
Open an alert if not open.
```bash
> alert_open [-stdin] [-${alert_type}] [-groups,-g "X,..."] ["alert_id"] "alert_title"
# -stdin: Reads data from standard input. Alert is only opened when there is data.
# -group: List of one or more contact groups to route the alert to.
# alert_id: Option ID for this alert. If not provided a modified form of the title is used.
# alert_title: Title of the alert. Appears in subject line of any messages.
# __alert_default_alert_type: Defines the default alert type.
```

### alert_send
Sends the alert to messaging using 'send_message'.
```bash
> alert_send "alert_id"
```

### alert_is_open
Return true an alert is already opened.
```bash
> alert_is_open "alert_id"
```

### alert_close
Close an alert.
```bash
> alert_close "alert_id"
# alert_id: Alert
```

### alerts_list
Return the list of open alert ID's.
```bash
> alerts_list [-l]
```

### alerts_count
Returns the number of open alerts.
```bash
> alerts_count
```

### alerts_check
Runs through all open alerts and sends them if they are due. Called from a schedule task.
```bash
> alerts_check
```

### alerts_close_all
Close all open alerts.
```bash
> alerts_close_all
```

