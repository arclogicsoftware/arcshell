

function expression_test {
   typeset x
   x="${1}"
   echo ${x%%,*}
}

function read_test {
   typeset x
   x="${1}"
   IFS="," read foo bar <<< "${x}"
   echo "${foo}"
}

echo "Begin expression_test: $(date)"
x=0
while (( ${x} < 10000 )); do
   expression_test "a,b,c" 1> /dev/null
   ((x=x+1))
done
echo "End expression_test: $(date)"

echo "Begin read_test: $(date)"
x=0
while (( ${x} < 10000 )); do
   read_test "a,b,c" 1> /dev/null
   ((x=x+1))
done
echo "End read_test: $(date)"

