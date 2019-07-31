# initialstate-dev.sh



## Reference


### initialstate_create_bucket
Creates a new InitialState bucket.
```bash
> initialstate_create_bucket "bucket_name"
# bucket_name: Name of bucket. Key will be generated using the name.
```

### initialstate_post_stat
Post a stat to a bucket.
```bash
> initialstate_post_stat [-bucket,-b "X"] "statname=value"
# bucket: Bucket name.
```

### initialstate_post_stream
Reads standard input and posts each value.
```bash
> initial_state_post_stream [-bucket,-b "X"]
```

### initialstate_test

