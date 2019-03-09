# unittest.sh

Build simple, elegant, unit tests for libraries written in shell (bash or ksh). The quickest way to get started is to watch the free training videos, which can be [found here](https://arclogicsoftware.com/arcshell_test_framework). 

## Reference


### unittest_debug_on
Enable debug dumps if debug is loaded. Defaults to on.
```bash
> unittest_debug_on
```

### unittest_debug_off
Disble debug dumpes.
```bash
> unitest_debug_off
```

### unittest_dump_debug_on
Enables automatic debug dumps after passing tests.
```bash
> unittest_dump_debug_on
```

### unittest_dump_debug_off
Disables automatic debug dumps after passing tests.
```bash
> unittest_dump_debug_off
```

### unittest_header
Define one or more lines to run before running the tests for a file.
```bash
> unittest_header [ -stdin | "header_text" ]
```

### unittest_test
Run the tests associated with a file.
```bash
> unittest_test [-tap,-t] [-lint,-l] [-shell,-s "X"] "file" "[regex]"
# -tap: Return results using Test Anything Protocal.
# -lint: Runs lint tests instead of normal unit tests..
# file: Test file. Use full path.
# regex: Limit tests to those matching ```regex```.
```

### unittest_cleanup
Cleans up header and temporary files after running a series of unit tests.
```bash
> unittest_cleanup
```

### pass_test
Signals a passing test.
```bash
> pass_test
```

### fail_test
Signals a failing test.
```bash
> fail_test ["test_failure_message"]
# test_failure_message: Test failure message.
```

### assert
Tests ```stdin``` against the defined options.
```bash
> assert [!] [-lines,-l X|-f|-d|-n|-z|X|"str"] ["test_failure_message"]
# !: Not operator.
# -lines: Input should match X number of lines.
# -f: Input is existing file.
# -d: Input is existing directory.
# -n: Input exists.
# -z: Input is null.
# X: Input equals number.
# str: Input equals string.
```

### assert_true
Assert that ```assertion``` is true.
```bash
> assert_true assertion ["test_failure_message"]
```

### assert_false
Assert that ```assertion``` is false.
```bash
> assert_false assertion ["test_failure_message"]
```

### assert_sleep
Sleep for ```X``` seconds.
```bash
> assert_sleep X
```

### assert_banner
Injects a message during testing. For example of you need to warn about some expected error or something.
```bash
> assert_banner "str"
```

### assert_match
Asserts that at least one line from ```stdin``` matches ```regex```.
```bash
> assert_match "regex" ["test_failure_message"]
```

### assert_nomatch
Asserts that none of the lines read from ```stdin``` match ```regex```.
```bash
> assert_nomatch "regex" ["test_failure_message"]
```

