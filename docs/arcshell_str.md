# Strings

**Library loaded with string functions.**

There are a number of string related functions in this library. In most cases the name of the function should make the purpose clear.



## Reference


### str_shuffle_lines
Shuffle input or lines from a file.
```bash
> str_shuffle_lines [-stdin] "file_name"
```

### str_return_matching_column_num
Returns the matching column number for the given column name from input.
```bash
> str_return_matching_column_num [-stdin] ["file_name"] "column_name"
# -stdin: Read input from standard in.
# file_name: Read input from file name.
# column_name: Name of column to match on.
```

### str_append_to_file_if_missing
Append standard input to a file if expression does not match on at least one line.
str_append_to_file_if_missing [-stdin] "regex" "file"
-stdin: Optional but assumed.
regex: Regular expresion.
file: File to append input to.

### str_uniq
Returns unique lines in a file without sorting them.
```bash
> str_uniq [-stdin] ["file"]
```

### str_remove_comments
Returns input with Unix styled comments removed.
Warning: This function will also remove commented lines in <<EOF blocks.
```bash
> str_remove_comments [-stdin] ["file"]
```

### str_replace_file_name
Replaces the file name only (not the extension) in a file name or path.
Note: Compressed tar files include the .tar. as part of file extension.
```bash
> str_replace_file_name "filePath" "newFileName"
# filePath: File name or file path, does actually need to exist yet.
# newFileName: The string to use to replace the file name in filePath.
```

### str_capitalize
Capitalize the first letter of each word in a string.
```bash
> str_capitalize [-stdin|"string" ]
```

### str_escape
Add backslashes to the following characters, .[]()*$, and return string.
```bash
> str_escape [-stdin] ["string"]
# -stdin: Read standard input.
```

### str_return_part_between_words
```bash
> str_return_part_between_words [-defaultValue "X"] [-startWord,-s "X"] [-endWord,-e "X"] "inputStr"
# -defaultValue: Return value if nothing else is found.
# -startWord: Option start word, else beginning of inputStr is assumed.
# -endWord: Optional end word, else end of inputStr is assumed.
# inputStr: String being evaluated.
# **Example**
# ```
# $ str_return_part_between_words -s "mission" -e "important" \
# > "This mission is too important for me to allow you to jeopardize it."
# is too
# ```
```

### str_len
Read input or standard input and return the length of a string.
```bash
> str_len [-stdin] ["string"]
# string: With no "string", read STDIN.
# 
# **Example**
# ```
# $ str_len "/home/poste/Dropbox/arcshell/core"
# 33
# $ echo "/home/poste/Dropbox/arcshell/core" | str_len -stdin
# 33
# ```
```

### str_center2

```bash
> str_center2 "length" "character"
```

### str_center
Centers a string.
```bash
> str_center [-width X] [-outline] "string"
# -width: Defaults to 80.
# -outline: Creates a box around the text.
# string: String to center.
# 
# **Example**
# ```
# $ str_center -w 20 -o "ArcShell"
# --------------------
# | ArcShell |
# --------------------
# 
```

### str_to_table
Formats string inputs into rows and columns.
```bash
> str_to_table [-columns "X,"] [-outline] "string" "string"
# -columns: Comma separated list of column sizes. Defaults to "40,40".
# -outline: Outlines the cells.
# string: Series of strings to be formated.
# 
# **Example**
# ```
# $ (
# > str_to_table -c "20,20" -o "State" "City"
# > str_to_table -c "20,20" -o "TX" "Dallas"
# > str_to_table -c "20,20" -o "CO" "Denver"
# > )
# | State | City |
# ----------------------------------------------
# | TX | Dallas |
# ----------------------------------------------
# | CO | Denver |
# ----------------------------------------------
# ```
```

### str_to_arg_stream
Return textString as a series of lines in which each line is one of the args.
```bash
> str_to_arg_stream "textString"
# textString: Text similar to a command line argument string.
```

### str_to_char_stream
Convert textString to a series of single character lines.
```bash
> str_to_char_stream "textString"
```

### str_repeat
Repeat a single or multi character string N times.
```bash
> str_repeat "string" N
# string: Character(s) to repeat.
# N: Repeat count.
# 
# **Example**
# ```
# $ str_repeat "-" 20
# --------------------
# ```
```

### str_to_key_str
Return input string after replacing most special chars with a '_'.
```bash
> str_to_key_str "string"
```

### str_get_next_word
Return the word following a word in a string of words.
```bash
> str_get_next_word "searchWord" "textString"
# searchWord: Word to search for in textString, when found next word is returned.
# textString: String of words to search. With no "textString", read STDIN.
# 
# **Example**
# ```
# $ echo "# from foo import "bar"" | str_get_next_word "from"
# foo
# $ str_get_next_word "from" "# from foo import "bar""
# foo
# ```
```

### str_get_word_num
Return the N'th word in line.

```bash
> str_get_word_num N "stringOfWords"
# N: Integer determines which word is returned.
# stringOfWords: Sentence or list of words/values separated by spaces.
# 
# **Example**
# ```
# $ str_get_word_num 2 "$(date)"
# Apr
# $ date | str_get_word_num 2
# Apr
# ```
```

### str_get_last_word
Return last word in a string or each line read from standard input.
```bash
> str_get_last_word [-stdin|"string" ]
```

### str_reverse_cat
Returns lines in reverse order from a file or standard input.
```bash
> str_reverse_cat [-stdin] "file_name"
# 
# **Example**
# ```
# (
# > cat <<EOF
# > A
# > B
# > EOF
# > ) | str_reverse_cat
# B
# A
# ```
```

### str_is_blank_line
Check if line is blank. Tabs, spaces and line returns are counted as blanks.
```bash
> str_is_blank_line "textString"
# 
# **Example**
# ```
# textString=" "
# $(str_is_blank_line "${textString}") && echo "Yes"
# ```
```

### str_remove_leading_blank_lines
Remove leading blank lines from a file or standard input.
```bash
> str_remove_leading_blank_lines "${file_name}"
# 
# **Example**
# ```
# str_remove_leading_blank_lines /tmp/example.txt
# cat /tmp/example.txt | str_remove_leading_blank_lines
# ```
```

### str_to_csv
Return a comma separated line to standard output

```bash
> str_to_csv ["delimiter"]
# delimiter: Delimiter, defaults to comma.
# **Example**
# ```
# $ (
# > cat <<EOF
# > a
# > b
# > EOF
# > ) | str_to_csv
# a,b
# ```
```

### str_get_last_char
Return last character in a ```string```.
```bash
> str_get_last_char [-stdin|"string"]
```

### str_reverse_line
Reverse the characters ```string```.
```bash
> str_reverse_line [-stdin|"string"]
```

### str_trim_line
Remove leading and trailing blanks from a ```string```.
```bash
> str_trim_line [-stdin|"string"]
```

### str_get_char_count
Return the number of times a character appears in a string.
```bash
> str_get_char_count [-stdin] "character" ["string"]
```

### str_split_line
Read standard in and split into separate lines using a token.
```bash
> str_split_line [-stdin] "token"
# token: Character to split on. Default is comma. A space is acceptable.
```

### str_to_upper_case
Converts 'string' to upper-case.
```bash
> str_to_upper_case [-stdin|"string"]
```

### str_is_upper_case
Return true if ```string``` is upper-case.
```bash
> str_is_upper_case "string"
```

### str_to_lower_case
Convert ```string``` to lower-case.
```bash
> str_to_lower_case [-stdin|"string"]
```

### str_is_lower_case
Return true if the ```string``` is lower-case.
```bash
> str_is_lower_case "string"
```

### str_is_word_in_list
Return true if ```word`` is found in ```list```.
```bash
> str_is_word_in_list "word" "list"
# word: Word to search for.
# list: List of words separated by spaces or a comma.
```

### str_instr
Return position of ```str``` within ```string```.
```bash
> str_instr "str" "string"
# str: String to search for.
# string: String to search.
```

### str_replace_tabs_with_space
Replace tab characters in ```string``` with a single space.
```bash
> str_replace_tabs_with_space [-stdin|"string"]
```

### str_replace_end_of_line_with_slash_n
Returns input and replaces line endings with literal "\n". Used for JSON data primarily.
```bash
> str_replace_end_of_line_with_slash_n [-stdin|"file"]
```

### str_remove_spaces
Remove spaces from ```string```.
```bash
> str_remove_spaces [-stdin|"string"]
```

### str_remove_double_spaces
Replace double spaces in ```string``` with single spaces.
```bash
> str_remove_double_spaces [-stdin|"string"]
# Todo: Better name.
```

### str_remove_control_m
Remove Control ^M characters from ```string```.
```bash
> str_remove_control_m [-stdin|"string"]
```

### str_remove_ticks_and_quotes
Remove single ticks and double quote characters from input.
```bash
> str_remove_ticks_and_quotes [-stdin|"string"]
```

### str_is_key_str
Return true if string is a key string.
```bash
> str_is_key_str "string"
# string: Key strings are restricted to "a-z", "0-9", "A-Z", "-". ".", and "_".
```

### str_raise_not_a_key_str
Throws an error and return true if the provided string is not a key string.
```bash
> str_raise_not_a_key_str ["source_of_call"] "string"
# source_of_call: A string which usually identifies the caller.
# string: Key strings are restricted to "a-z", "0-9", "A-Z", "-". ".", and "_".
```

