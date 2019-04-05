> The really good programmers spend a lot of time programming. I haven’t seen very good programmers who don’t spend a lot of time programming. If I don’t program for two or three days, I need to do it. And you get better at it—you get quicker at it. The side effect of writing all this other stuff is that when you get to doing ordinary problems, you can do them very quickly. -- Joe Armstrong

# SendGrid

**SendGrid interface.**



## Reference


### sendgrid_send
Sends the message from standard in using SendGrid API settings.
```bash
> sendgrid_send -a "X" -s "X" "to"
# -a: From address.
# -s: Subject text.
# to: Comma separated list of email addresses.
```

