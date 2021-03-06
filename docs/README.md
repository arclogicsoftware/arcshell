# Modules Reference

| Module | About |
| --- | --- |
| [Alerting](#alerting) | Easily incorporate recurring alerts and notifications into your scripts. |
| [ArcShell](#arcshell) | Contains functions to manage local and remote ArcShell nodes. |
| [Caching](#caching) | A simple yet powerful key value data store. |
| [Chat](#chat) | Supports sending messages to services like Slack. |
| [Compiler](#compiler) | Transforms modules with multiple dependencies into single executable files. |
| [Configuration](#configuration) | Manage configuration files. |
| [Contact Groups](#contact_groups) | Manages group membership and the rules used to send messages to the group. |
| [Counters](#counters) | A fast counter management mechanism. |
| [Cron](#cron) | Make and schedule solutions using cron styled attributes. |
| [Demo](#demo) | Create playable command line demonstrations. |
| [Documentation Engine](#documentation_engine) | Generate documentation and help commands from source files. |
| [Dates & Times](#dates_times) | Makes working with dates and times easier. |
| [Event Counter](#event_counter) | This module counts things using text based indicators. |
| [Files](#files) | Simplifies many common file and directory related tasks. |
| [Flags](#flags) | Simple way to set and retrieve a keyed value. |
| [Google Charts](#google_charts) | A module for generating charts using Google Charts. |
| [Keywords](#keywords) | Manages ArcShell keywords. |
| [Locking](#locking) | Creates and manages locks for you. |
| [Logging](#logging) | Logs stuff. |
| [Log Monitoring](#log_monitoring) | Monitor log files. Trigger alerts, notifications, and log entries using flexible log file handlers. |
| [Menus](#menus) | Builds rich command line menu systems that are dynamic. |
| [Messaging](#messaging) | Manages the routing and sending of messages. |
| [Numbers](#numbers) | Number and math functions. |
| [Objects](#objects) | Manages object styled data structures. |
| [OS](#os) | Basic operating system related functions for Unix/Linux. |
| [Packager](#packager) | Package a directory for deployment or distribution to remote nodes. |
| [rsync](#rsync) | A simple rsync interface. |
| [Scheduler](#scheduler) | Easily create scheduled tasks. |
| [SendGrid](#sendgrid) | SendGrid interface. |
| [Sensors](#sensors) | Detects changes or things that have not changed. |
| [SSH Connection Manager](#ssh_connection_manager) | SSH connection manager. |
| [SSH](#ssh) | Connect using SSH and execute remote scripts or commands. |
| [Data Stacks](#data_stacks) | Create and manage small data stacks which operate a little like arrays. |
| [Statistics - Extended](#statistics_-_extended) | Extends capabilities of the statistics interface. |
| [Statistics](#statistics) | Stores statistics. Performs aggregation, analysis, and anomaly detection. |
| [Strings](#strings) | Library loaded with string functions. |
| [Tar](#tar) | This module is used to to work with tar files. |
| [Threshold Monitor](#threshold_monitor) | Monitors values based on thresholds combined with time limits. |
| [Timeout](#timeout) | Implement timeouts to kill hung processes and perform other time dependent tasks. |
| [Timer](#timer) | Create and manage timers for timing all sorts of things. |
| [Utilities](#utilities) | Misc. utilities. |
| [Watcher](#watcher) | Watches files, directories, processes and other things. |
| [Debug](#debug) | Provides advanced debug capabiltiies. |
| [Unit Testing](#unit_testing) | A unit test library for bash and korn shells. |

----
<a name="alerting"/>

![alarm-clock-1.png](./images/alarm-clock-1.png)

## Alerting (arcshell_alerts.sh)

Easily incorporate recurring alerts and notifications into your scripts.

## Example(s)
```bash

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

### Links

* [Reference](./arcshell_alerts.md)


----

<a name="arcshell"/>

![network.png](./images/network.png)

## ArcShell (arcshell_arc.sh)

Contains functions to manage local and remote ArcShell nodes.

## Example(s)
```bash

   # Package the current ArcShell home.
   arc_pkg 
   # Set the SSH connection to 'tst'. 'tst' is already configured as an SSH connection.
   ssh_set "tst"
   # Setup ArcShell on 'tst' using the package we just created. 
   arc_install -force
   # Assume some change has been made. Re-package the current ArcShell home.
   arc_pkg 
   # Update the remote ArcShell home on 'tst' using the new package.
   arc_update 
   # Assume another change has been made.
   # Use rsync to sync the current ArcShell home to 'tst' home. This skips the packaging step.
   arc_sync
   # Remove ArcShell from the report 'tst' home/
   arc_uninstall
```

### Links

* [Reference](./arcshell_arc.md)


----

<a name="caching"/>

![key.png](./images/key.png)

## Caching (arcshell_cache.sh)

A simple yet powerful key value data store.

## Example(s)
```bash

   # Cache a value for 'city'.
   cache_save "city" "Nashville"
   # Get the value of 'city'.
   x="$(cache_get "city")"
   echo "City is ${x}."
```

### Links

* [Reference](./arcshell_cache.md)


----

<a name="chat"/>

![smartphone-10.png](./images/smartphone-10.png)

## Chat (arcshell_chat.sh)

Supports sending messages to services like Slack.

## Example(s)
```bash


  # Post vmstat data to Slack
  vmstat 5 5 | send_slack -stdin 

  # Post a simple message to Slack.
  send_slack "Build is complete."

  # Messages can also be posted to Slack using the messaging system.
  vmstat 5 5 | send_message -slack "This is a Slack message too."

```

### Links

* [Reference](./arcshell_chat.md)


----

<a name="compiler"/>



## Compiler (arcshell_compiler.sh)

Transforms modules with multiple dependencies into single executable files.



### Links

* [Reference](./arcshell_compiler.md)


----

<a name="configuration"/>

![switch-4.png](./images/switch-4.png)

## Configuration (arcshell_config.sh)

Manage configuration files.



### Links

* [Reference](./arcshell_config.md)


----

<a name="contact_groups"/>

![user-6.png](./images/user-6.png)

## Contact Groups (arcshell_contact_groups.sh)

Manages group membership and the rules used to send messages to the group.



### Links

* [Reference](./arcshell_contact_groups.md)


----

<a name="counters"/>

![add-1.png](./images/add-1.png)

## Counters (arcshell_counters.sh)

A fast counter management mechanism.

## Example(s)
```bash


   # Deletes a counter group and all associated files.
   counters_delete_group "foo"

   # Creates a new counter called 'sheep' in the foo group.
   counters_set "foo,sheep,+1"

   # Increments the counter by 1.
   counters_set "foo,sheep,+1"

   # This will return 0. The increment in last step is not
   # available until 'counters_update' is called.
   counters_get "foo,sheep"

   # For examples to return correct values below we need
   # to set this to 0. Normally most recent file is not
   # included in 'counters_update' but when this is 0 it is.
   _g_counterSafeMode=0

   # Set the counter to ten.
   counters_set "foo,sheep,=10"

   # Force update and check value. Will return 10.
   counters_update
   counters_get "foo,sheep"

   # Let's add an animal to the group.
   counters_set "foo,cow,=3"

   # Subtract a cow.
   counters_set "foo,cow,-1"

   # Return all counter values in the group. Returns 10 and 2.
   counters_update
   counters_get "foo"

   counters_delete_group "foo"
   counters_get_group "foo"

   # This returns 0. 0 returned when a counter does not exist.
   counters_get "animals,horses"
```

### Links

* [Reference](./arcshell_counters.md)


----

<a name="cron"/>

![clock.png](./images/clock.png)

## Cron (arcshell_cron.sh)

Make and schedule solutions using cron styled attributes.

## Example(s)
```bash

   if cron_is_true "* 8-16 * * *"; then
      echo "Hour is between 8AM and 4PM."
   fi
```

### Links

* [Reference](./arcshell_cron.md)


----

<a name="demo"/>

![record.png](./images/record.png)

## Demo (arcshell_demo.sh)

Create playable command line demonstrations.



### Links

* [Reference](./arcshell_demo.md)


----

<a name="documentation_engine"/>

![compose.png](./images/compose.png)

## Documentation Engine (arcshell_doceng.sh)

Generate documentation and help commands from source files.



### Links

* [Reference](./arcshell_doceng.md)


----

<a name="dates_times"/>

![calendar-5.png](./images/calendar-5.png)

## Dates & Times (arcshell_dt.sh)

Makes working with dates and times easier.



### Links

* [Reference](./arcshell_dt.md)


----

<a name="event_counter"/>

![view-1.png](./images/view-1.png)

## Event Counter (arcshell_event_counter.sh)

This module counts things using text based indicators.



### Links

* [Reference](./arcshell_event_counter.md)


----

<a name="files"/>

![file.png](./images/file.png)

## Files (arcshell_file.sh)

Simplifies many common file and directory related tasks.



### Links

* [Reference](./arcshell_file.md)


----

<a name="flags"/>

![flag-4.png](./images/flag-4.png)

## Flags (arcshell_flags.sh)

Simple way to set and retrieve a keyed value.

## Example(s)
```bash

   # Set a flag.
   flag_set "status" "active"
   # Check to see if the flag exists.
   if flag_exists "status"; then
      echo "The 'status' flag exists."
   fi
   # Get the value of a flag.
   if [[ "$(flag_get 'status')" == "active" ]]; then
      flag_set "status" "inactive"
   fi
   # Unset (remove) the flag.
   flag_unset "status"
```

### Links

* [Reference](./arcshell_flags.md)


----

<a name="google_charts"/>

![diamond.png](./images/diamond.png)

## Google Charts (arcshell_gchart.sh)

A module for generating charts using Google Charts.



### Links

* [Reference](./arcshell_gchart.md)


----

<a name="keywords"/>

![sign-1.png](./images/sign-1.png)

## Keywords (arcshell_keywords.sh)

Manages ArcShell keywords.



### Links

* [Reference](./arcshell_keywords.md)


----

<a name="locking"/>

![lock.png](./images/lock.png)

## Locking (arcshell_lock.sh)

Creates and manages locks for you.



### Links

* [Reference](./arcshell_lock.md)


----

<a name="logging"/>

![infinity.png](./images/infinity.png)

## Logging (arcshell_logger.sh)

Logs stuff.



### Links

* [Reference](./arcshell_logger.md)


----

<a name="log_monitoring"/>

![view.png](./images/view.png)

## Log Monitoring (arcshell_logmon.sh)

Monitor log files. Trigger alerts, notifications, and log entries using flexible log file handlers.



### Links

* [Reference](./arcshell_logmon.md)


----

<a name="menus"/>

![menu-3.png](./images/menu-3.png)

## Menus (arcshell_menu.sh)

Builds rich command line menu systems that are dynamic.



### Links

* [Reference](./arcshell_menu.md)


----

<a name="messaging"/>

![smartphone-1.png](./images/smartphone-1.png)

## Messaging (arcshell_msg.sh)

Manages the routing and sending of messages.



### Links

* [Reference](./arcshell_msg.md)


----

<a name="numbers"/>

![division.png](./images/division.png)

## Numbers (arcshell_num.sh)

Number and math functions.



### Links

* [Reference](./arcshell_num.md)


----

<a name="objects"/>

![database-2.png](./images/database-2.png)

## Objects (arcshell_obj.sh)

Manages object styled data structures.

## Example(s)
```bash

   echo "Returning the contents of the persons.cfg file..."
   cat "${arcHome}/config/object_models/persons.cfg"
   echo ""

   echo "Saving record 'Ethan'..."
   eval "$(objects_init_object "persons")"
   name="Ethan"
   birthdate="19010101"
   objects_save_object "persons" "Ethan"

   echo "Saving record 'Tucker'..."
   eval "$(objects_init_object "persons")"
   name="Tucker"
   objects_save_object "persons" "Tucker"

   echo "Listing all objects or type 'persons'..."
   objects_list_objects "persons"

   echo "Loading 'Ethan' and returning values..."
   eval "$(objects_load_object "persons" "Ethan")"
   echo "${name}:${birthdate}"

   echo "Loading 'Tucker' and returning values..."
   eval "$(objects_load_object "persons" "Tucker")"
   echo "${name}:${birthdate}"

   objects_delete_object "persons" "Ethan"
   objects_delete_object "persons" "Tucker"
```

### Links

* [Reference](./arcshell_obj.md)


----

<a name="os"/>

![server.png](./images/server.png)

## OS (arcshell_os.sh)

Basic operating system related functions for Unix/Linux.



### Links

* [Reference](./arcshell_os.md)


----

<a name="packager"/>

![gift.png](./images/gift.png)

## Packager (arcshell_pkg.sh)

Package a directory for deployment or distribution to remote nodes.



### Links

* [Reference](./arcshell_pkg.md)


----

<a name="rsync"/>

![repeat-1.png](./images/repeat-1.png)

## rsync (arcshell_rsync.sh)

A simple rsync interface.



### Links

* [Reference](./arcshell_rsync.md)


----

<a name="scheduler"/>

![clock-1.png](./images/clock-1.png)

## Scheduler (arcshell_sch.sh)

Easily create scheduled tasks.



### Links

* [Reference](./arcshell_sch.md)


----

<a name="sendgrid"/>

![incoming.png](./images/incoming.png)

## SendGrid (arcshell_sendgrid.sh)

SendGrid interface.



### Links

* [Reference](./arcshell_sendgrid.md)


----

<a name="sensors"/>

![compass.png](./images/compass.png)

## Sensors (arcshell_sensor.sh)

Detects changes or things that have not changed.



### Links

* [Reference](./arcshell_sensor.md)


----

<a name="ssh_connection_manager"/>

![id-card-2.png](./images/id-card-2.png)

## SSH Connection Manager (arcshell_ssh_connections.sh)

SSH connection manager.



### Links

* [Reference](./arcshell_ssh_connections.md)


----

<a name="ssh"/>

![cloud-computing-1.png](./images/cloud-computing-1.png)

## SSH (arcshell_ssh.sh)

Connect using SSH and execute remote scripts or commands.



### Links

* [Reference](./arcshell_ssh.md)


----

<a name="data_stacks"/>

![layers.png](./images/layers.png)

## Data Stacks (arcshell_stack.sh)

Create and manage small data stacks which operate a little like arrays.



### Links

* [Reference](./arcshell_stack.md)


----

<a name="statistics_-_extended"/>



## Statistics - Extended (arcshell_stats_ext.sh)

Extends capabilities of the statistics interface.



### Links

* [Reference](./arcshell_stats_ext.md)


----

<a name="statistics"/>

![radar.png](./images/radar.png)

## Statistics (arcshell_stats.sh)

Stores statistics. Performs aggregation, analysis, and anomaly detection.



### Links

* [Reference](./arcshell_stats.md)


----

<a name="strings"/>

![command.png](./images/command.png)

## Strings (arcshell_str.sh)

Library loaded with string functions.



### Links

* [Reference](./arcshell_str.md)


----

<a name="tar"/>

![archive-2.png](./images/archive-2.png)

## Tar (arcshell_tar.sh)

This module is used to to work with tar files.



### Links

* [Reference](./arcshell_tar.md)


----

<a name="threshold_monitor"/>

![battery-6.png](./images/battery-6.png)

## Threshold Monitor (arcshell_threshold_monitor.sh)

Monitors values based on thresholds combined with time limits.

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

### Links

* [Reference](./arcshell_threshold_monitor.md)


----

<a name="timeout"/>

![hourglass.png](./images/hourglass.png)

## Timeout (arcshell_timeout.sh)

Implement timeouts to kill hung processes and perform other time dependent tasks.



### Links

* [Reference](./arcshell_timeout.md)


----

<a name="timer"/>

![stopwatch-1.png](./images/stopwatch-1.png)

## Timer (arcshell_timer.sh)

Create and manage timers for timing all sorts of things.

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

### Links

* [Reference](./arcshell_timer.md)


----

<a name="utilities"/>

![magnet.png](./images/magnet.png)

## Utilities (arcshell_utl.sh)

Misc. utilities.



### Links

* [Reference](./arcshell_utl.md)


----

<a name="watcher"/>

![spotlight.png](./images/spotlight.png)

## Watcher (arcshell_watch.sh)

Watches files, directories, processes and other things.



### Links

* [Reference](./arcshell_watch.md)


----

<a name="debug"/>

![blueprint.png](./images/blueprint.png)

## Debug (debug.sh)

Provides advanced debug capabiltiies.



### Links

* [Reference](./debug.md)


----

<a name="unit_testing"/>

![list.png](./images/list.png)

## Unit Testing (unittest.sh)

A unit test library for bash and korn shells.



### Links

* [Reference](./unittest.md)


----

