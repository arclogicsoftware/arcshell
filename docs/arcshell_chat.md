> Programming is not like being in the CIA; you don't get credit for being sneaky. It's more like advertising; you get lots of credit for making your connections as blatant as possible. -- Steve McConnell 

# Chat

**Supports sending messages to services like Slack.**

This module currently supports Slack. You will need to obtain a web hook from Slack which enables you to post messages to a single channel. You will specify the allowed channel when you create the web hook. 

You will need to set the ```arcshell_app_slack_webhook``` value in one of the ```arcshell.cfg``` configuration files. Do not modify the delivered file. Instead modify your global or user version. These are located in ```${arcGlobalHome}/config/arcshell``` and ```${arcUserHome}/config/arcshell``` directories.

You can optionally set the value of this parameter in the configuration file for a specific **contact group**.

## Example(s)
```bash


  # Post vmstat data to Slack
  vmstat 5 5 | send_slack -stdin 

  # Post a simple message to Slack.
  send_slack "Build is complete."

  # Messages can also be posted to Slack using the messaging system.
  vmstat 5 5 | send_message -slack "This is a Slack message too."

```

## Reference


### send_slack
Post a message to the configured slack channel.
```bash
> send_slack [-stdin] ["slack_message"]
# -stdin: Get message from standard input.
# slack_message: Get message from this variable.
```

