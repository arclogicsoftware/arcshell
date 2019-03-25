Keywords are found in the ```${arcHome}/config/keywords``` folder.

To change the settings for a keyword copy the keyword file to the ```${arcGlobalHome}/config/keywords``` folder or ```${arcUserHome}/config/keywords``` and modify it. 

Keywords can be created by placing new files in one of these two folders. We recommend keeping the number of keywords to a minimum.

When ArcShell loads a keyword it loads all files in top down order. Delivered, global, then user.

**Example of a keyword configuration file.**

Truthy values are allowable. 

Keyword configuration files are shell scripts. You can use shell to conditionally set the values.

```
# ${arcHome}/config/keywords/critical.cfg
#
# Truthy values including ArcShell cron expressions are acceptable.
send_text=1
send_email=1
send_slack=0

# This char is used by the event_module to log each send_message.
event_counter_char="!"
```



## Reference


### keyword_raise_not_found
Raise error and return true if the keyword is not found.
```bash
> keyword_raise_not_found "keyword"
```

### keyword_does_exist
Return true if the keyword exists.
```bash
> keyword_does_exist
```

### keyword_load
Returns the strings to load all keyword configuration files in top down order.
```bash
> eval "$(keyword_load 'keyword')"
```

### keywords_count
Return the number of defined keywords.
```bash
> keywords_count
```

### keywords_list
Return the list of all keywords.
```bash
> keywords_list [-l|-a]
# -l: Long list. Include file path to the keyword configuration file.
# -a: All. List every configuration file for every keyword.
```

