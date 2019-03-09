# arcshell_num.sh

## Reference


### num_line_count
Returns line count. Removes any left padded blanks that may show up in Solaris with wc use.
```bash
> num_line_count [-stdin] ["file_name"]
```

### num_random
Return a random number between two values.
```bash
> num_random [minValue=0] maxValue
```

### num_round_to_multiple_of
Round a whole number to the nearest multiple of another number.
```bash
> num_round_to_multiple_of "numberToRound" "roundToNearest"
# numberToRound: The number that needs to be rounded.
# roundToNearest: Round the number above to the nearest multiple of this number.
```

### num_floor
Return the whole number floor of a number.
```bash
> num_floor [-stdin] X
# X: A number, can be a decimal.
```

### num_is_whole
Return true if a number is a whole number.
```bash
> num_is_whole X
```

### num_is_even
Return true if number is whole number and is even.

```bash
> num_is_even X
# X: Any whole number.
# 
# **Example**
# ```
# num_is_even 4 && echo "True" || echo "False"
# True
# ```
```

### num_is_odd
Return true if number is whole number and is odd.

```bash
> num_is_odd X
# X: Any whole number.
# 
# **Example**
# ```
# $(num_is_odd 4) && echo "True" || echo "False"
# False
# ```
```

### num_is_gt
Return true if first value is greater than the second. Decimals are allowed.
```bash
> num_is_gt isThisNum gtThanThisNum
# isThisNum: Integer or decimal.
# gtThanThisNum: Integer or decimal.
```

### num_range
Return a range of whole numbers from beginning value to ending value.
```bash
> num_range start end
# start: Whole number to start with.
# end: Whole number to end with.
```

### num_max
Get max from a series of numbers. Numbers are supplied as argments or standard input. Decimals are allowable.
```bash
> num_max [X...]
# X: One or more numbers separated by spaces.
```

### num_min
Get min from a series of numbers. Numbers are supplied as argments or standard input. Decimals are allowable.
```bash
> num_min [X...]
# X: One or more numbers separated by spaces.
```

### num_sum
Sum a series of integer or decimal numbers.
```bash
> num_sum [-stdin] [-decimals,-d X] [X...]
# decimals: Specify the # of decimals. Defaults to zero.
# -stdin: Read from standard input.
# X: One or more numbers separated by spaces.
```

### num_avg
Avg a series of numbers. Numbers are supplied as argments or standard input. Decimals are allowable.
```bash
> num_avg [X...]
# X: One or more numbers separated by spaces.
```

### num_stddev
Get standard deviation from a series of numbers. Numbers are supplied as argments or standard input. Decimals are allowable.
```bash
> num_stddev [X...]
# X: One or more numbers separated by spaces.
```

### num_is_num
Return true if input value is a number. Decimals are allowable.
```bash
> num_is_num X
# X: The variable or string being tested.
```

### num_raise_is_not_a_number
Throw error and return true if provided value is not a number.
```bash
> num_raise_is_not_a_number "source" X
# source: Source of error.
# X: Expected number.
```

### num_correct_for_octal_error
Changes numbers like 08.1 to 8.1, because bash will interpret the former as an octal.

Google "bash value too great for base" to understand more. At the time of this
writing it is just used to strip leading zeros from some variables in the cron.sh
library.

This function also reads from standard input.

```bash
> num_correct_for_octal_error [-stdin | X ]
# X: Integer or decimal value with potential leading zeros.
```

### num_is_gt_zero
Return true if the number is greater than zero. Works with decimals.
```bash
> num_is_gt_zero X
# X: A number.
```

### num_is_zero
Ext true if the number is zero. Works with decimals.
```bash
> num_is_zero X
# X: A number.
```

