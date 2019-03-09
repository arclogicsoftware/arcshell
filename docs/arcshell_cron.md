Evaluates cron expressions. The following examples demonstrate the range of cron expressions allowable. See the Unix documentation for basic information on cron expressions. ArcShell supports the following features.

* Like typical cron entries, asterisks are wild cards.
* Ranges are allowed. For example, “0,15,30,45 8-17 * * *”, runs jobs at 4 times per hour between 8:00 AM and 5:59 PM.
* Reverse ranges are also allowed. For example, “/15 18-6 * * *”, also runs jobs 4 times per hour but between 6:00 PM and 6:59 AM. Not the example also uses a divisor, which is also allowable.
* Each field can contain more than one entry. For example, “0 2-4,6-8 * * *”, runs jobs at 2:00, 3:00, 4:00, 6:00, 7:00 and 8:00 AM. Just make sure there are no spaces within the individual fields.
* Months can be represented using digits (1-12) or 3-character abbreviations. For example, “0 12 * APR-SEP *” runs jobs at 12:00 AM every day between April and September.
* Day of week can be represented using digits (0-6 where 0 is Sunday) or three-character abbreviations. For example, “0 2 * * SUN-WED”, runs jobs at 2:00 AM Sunday through Wednesday.

## Reference


### cron_is_true
Return true if the provided cron expression is true.
```bash
> cron_is_true "cronExpression"
```

