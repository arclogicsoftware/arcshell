function test_get_arg2 {
  # Run the function and assert that the result is 'x', this will fail.
  get_arg2 "a" "b" | assert "x" "'x' should have been returned here."
}

