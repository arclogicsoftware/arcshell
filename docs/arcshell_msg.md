> Learning the art of programming, like most other disciplines, consists of first learning the rules and then learning when to break them. -- Joshua Bloch

# Messaging

**Manages the routing and sending of messages.**

ArcShell messaging works in conjunction with ArcShell [contact groups](https://github.com/arclogicsoftware/arcshell/blob/master/docs/arcshell_contact_groups.md) and ArcShell [keywords](https://github.com/arclogicsoftware/arcshell/blob/master/docs/arcshell_keywords.md) to determine who gets a message, how, and when.

Messages are sent using ```send_message```. This function expects to read the message from standard input. If no input exists a message will not be sent.

For example:
```
# This does not result in a message.
echo "" | send_message "This won't work."

# This does.
echo "foo" | send_message "This works!"
```
This behavior is by design. This makes it easy to deploy commands like this.
```
# The message is only sent when the sensor detects a change.
ls ${HOME} | sensor "home_dir_check" |    send_message -email "Change Detected!"
```
Messaging handles the following tasks:
* Identifies one or more default contact groups when they are not specified.
* Queues messages or rejects messages per contact group settings.
* Delivers messages when due to intended recipients using the means allowed.

This module should be used to replace most of your calls to mailx or mail. This module also supports Slack. 

----

## Hidden Variables

| Variable | Description |
| --- | --- | 
| __messaging_max_text_lines | Maximum number of lines to include when sending a text. Defaults to 3. |
| __messaging_max_email_lines | Maximum number of lines to include when sending an email. Defaults to 9999. |



## Reference


### msg_check
Returns a bunch of information about the state of messaging configuration.
```bash
> msg_check
```

### msg_reset_all_queues
Removes all messages from all queues for all groups.
```bash
> msg_reset_all_queues
```

### msg_check_message_queues
This function should be called periodically from the scheduler.
```bash
> msg_check_message_queues
```

### send_message
Create a message using standard input and route to the appropriate queues.
```bash
> send_message [-${keyword}] [-groups,-g "X,..."] [-now] ["subject"]
# -${keyword}: A valid mail message/alerting keyword.
# -groups: List of groups to route the message to. Groups override
# -now: Send message and skip queuing.
# subject: Message subject.
```

