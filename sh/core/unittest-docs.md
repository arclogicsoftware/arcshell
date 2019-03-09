# unit-test.sh (Arclogic Software's Unit-testing Framework)

## Introduction
Sometime in 2016 I became aware of the many benefits of test-driven-development and having unittests. At the time I could not find a well maintained library with good documentation that had all the features I wanted, so I wrote my own. This library is used extensivley in my automation development platform, ArcShell. I am happy to add features if they make sense and don't break existing functionality. 

Since writing my own library I have found others which you may want to look at before choosing this one. I have reviewed each one of these and incorporated features I thought were necessary.

[shUnit2](https://github.com/kward/shunit2)
[Bats](https://github.com/sstephenson/bats)
[bunit](https://github.com/rafritts/bunit)
[bash_unit](https://github.com/pgrange/bash_unit)

## Where can we store test?

I keep my tests in the same file as my code when I am doing development. Once the library is released/stablized I move the test code to a stand-alone file. This makes it easy for me to update code and tests without having to have more than one file open. One of my goals is to make test writing as easy as possible. 

Tests can go in one or more of four possible locations. Assume we have a source file called ```/home/user/myapp/sh/bar.sh```.
| Possible Test Files | About |
| ----------- | --------------- |
| /home/foo/sh/bar.sh | Tests can go in the source file. This is my preference for new development. |
| /home/foo/sh/bar.test | This is also valid. Create a file containing tests using the source file name but change the extension to ```.test```. | 
| /home/foo/test/bar.sh | Use the source file name but put the file containing tests in the ```test``` directory. ```test``` directories are one level above the source file. |
| /home/foo/sh/bar.test | You can also use the ```test``` directory but change the source file extension to ```.test```. |

**Import/Export Feature** An import/export feature is planned to make it easy to move tests from one file to another. This will make it easy to bring tests back into the source file during development and then export them back to a stand-alone file when you are ready.

## Writing our first test.
Here is the function we will use to tested.
```sh
# unitest_examples.sh
function get_arg2 {
    # This function returns the second argument.
  echo "${2}"
}
```
Tests are contained within functions which always start with ```test_```. You can put anything you want after that. My preference is to use the function name being tested. This makes it easy to associate the test with a particular function in the library. This is particularly important when the import/export feature is delivered. A test function can contain any number of tests.
```sh
```
You always need to provide the file being tested. The file may or may not contain tests. The framework will take care of locating the other files and sourcing in the tests if they exist.
```sh
./unit-test.sh $(pwd)/unitest_examples.sh

# -----------------------------------------------------------------------------
# Test File              : /media/sf_temp/arcshell/sh/core/unittest_examples.sh
# Last Result            : Failed
# Last Time              : 1 seconds
# Shell Path             : /bin/bash
# Shell Type             : bash
# -----------------------------------------------------------------------------
*** Test Dump ***
b
[ X ]  test_get_arg2_1: 'x' should have been returned here.
[ * ]  '[[ "b" == "x" ]]' is not true
[ X ]  /media/sf_temp/arcshell/sh/core/unittest_examples.sh: passed=0, failed=1
```


