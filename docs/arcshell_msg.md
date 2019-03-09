
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

