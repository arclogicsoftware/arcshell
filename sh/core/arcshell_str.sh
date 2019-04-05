
# module_name="Strings"
# module_about="Library loaded with string functions."
# module_version=1
# module_image="command.png"
# copyright_notice="Copyright 2019 Arclogic Software"

_strTestFile="${arcTmpDir}/string$$.test"

function __readmeStrings {
   cat <<EOF
> As a rule, software systems do not work well until they have been used, and have failed repeatedly, in real applications. -- Dave Parnas

# Strings

**Library loaded with string functions.**

There are a number of string related functions in this library. In most cases the name of the function should make the purpose clear.
EOF
}

function str_shuffle_lines {
   # Shuffle input or lines from a file.
   # >>> str_shuffle_lines [-stdin] "file_name"
   ${arcRequireBoundVariables}
   debug3 "str_shuffle_lines: $*"
   boot_raise_program_not_found "perl" && ${returnFalse} 
   if [[ "${1:-}" == "-stdin" ]] || (( $# == 0 )); then
      cat | perl -MList::Util=shuffle -e 'print shuffle(<STDIN>);'
   elif [[ -f "${1:-}" ]]; then
      perl -MList::Util=shuffle -e 'print shuffle(<STDIN>);' < "${1}"
   fi
   ${returnTrue} 
}

function test_str_shuffle_lines {
   :
}

function str_return_matching_column_num {
   # Returns the matching column number for the given column name from input.
   # >>> str_return_matching_column_num [-stdin] ["file_name"] "column_name"
   # -stdin: Read input from standard in.
   # file_name: Read input from file name.
   # column_name: Name of column to match on.
   ${arcRequireBoundVariables}
   typeset column_name i 
   i=0
   if [[ "${1}" == "-stdin" ]]; then
      shift
      column_name="${1}"
      cat | egrep " ${column_name} |^${column_name} | ${column_name}$" | \
         str_split_line -stdin " " | \
         utl_remove_blank_lines -stdin | \
         grep -n "^${column_name}$" | cut -d":" -f1
   else
      cat "${1}" | str_return_matching_column_num -stdin "${2}"
   fi
   ${returnTrue} 
}

function str_append_to_file_if_missing {
   # Append standard input to a file if expression does not match on at least one line.
   # str_append_to_file_if_missing [-stdin] "regex" "file"
   # -stdin: Optional but assumed.
   # regex: Regular expresion.
   # file: File to append input to.
   ${arcRequireBoundVariables}
   typeset regex file
   regex="${1}"
   file="${2}"
   file_raise_file_not_found "${file}" && ${returnFalse} 
   if ! egrep "${regex}" "${file}" 1> /dev/null; then
      cat >> "${file}"
   fi
   ${returnTrue} 
}

function test_str_append_to_file_if_missing {
   :
}

function _str_uniq {
   # Read standard input and return unique lines without sorting them to standard output.
   # >>> _str_uniq 
   if boot_is_program_found "perl"; then
      perl -ne 'print unless $seen{$_}++'
   else
      _str_uniq_awk
   fi
}

function _str_uniq_awk {
   # Read standard input and return unique lines without sorting them to standard output.
   # Note: This blows up on Solaris, you will need Perl there.
   # >>> _str_uniq_awk
   ${arcAwkProg} '!seen[$0]++'
}

function str_uniq {
   # Returns unique lines in a file without sorting them.
   # >>> str_uniq [-stdin] ["file"]
   ${arcRequireBoundVariables}
   if [[ "${1:-}" == "-stdin" ]]; then
      _str_uniq 
   else
      _str_uniq < "${1}"
   fi
}

function str_remove_comments {
   # Returns input with Unix styled comments removed.
   # Warning: This function will also remove commented lines in <<EOF blocks.
   # >>> str_remove_comments [-stdin] ["file"]
   ${arcRequireBoundVariables}
   if [[ "${1:-}" == "-stdin" ]]; then
      egrep -v "^ *#"
   else
      egrep -v "^ *#" "${1}"
   fi
}

function test_str_remove_comments {
   (
   cat <<EOF
Blah
# COMMENT
X=0
   # COMMENT
X=0
X=0 # KEEP THIS LINE
EOF
   ) > "${_strTestFile}"
   cat "${_strTestFile}" | str_remove_comments -stdin | grep "COMMENT" | assert -l 0
   cat "${_strTestFile}" | str_remove_comments -stdin | grep -v "COMMENT" | assert -l 4
}

function str_replace_file_name {
   # Replaces the file name only (not the extension) in a file name or path.
   # Note: Compressed tar files include the .tar. as part of file extension.
   # >>> str_replace_file_name "filePath" "newFileName"
   # filePath: File name or file path, does actually need to exist yet.
   # newFileName: The string to use to replace the file name in filePath.
   filePath="${1}"
   file_name="${2}"
   fileDir="$(dirname "${filePath}")"
   baseName="$(basename "${filePath}")"
   fileExt="$(file_get_ext "${baseName}")"
   echo "${fileDir}/${file_name}.${fileExt}"
}

function test_str_replace_file_name {
   str_replace_file_name "/tmp/foo.txt" "bar" | assert "/tmp/bar.txt"
   str_replace_file_name "/tmp/foo.tar.Z" "bar" | assert "/tmp/bar.tar.Z"
   str_replace_file_name "/tmp/foo.bin.tar.gz" "bar" | assert "/tmp/bar.tar.gz"
   str_replace_file_name "/tmp/foo.2018.03.21.tar.gz" "bar" | assert "/tmp/bar.tar.gz"
}

function str_capitalize {
   # Capitalize the first letter of each word in a string.
   # >>> str_capitalize [-stdin|"string" ]
   ${arcRequireBoundVariables}
   if [[ "${1:-}" == "-stdin" ]]; then
      ${arcAwkProg} '{for(i=1;i<=NF;i++){ $i=toupper(substr($i,1,1)) substr($i,2) }}1'
   else
      echo "${1:-}" | str_capitalize -stdin 
   fi
   ${returnTrue} 
}

function test_str_capitalize {
   echo "foo fi fum" | str_capitalize -stdin | assert "Foo Fi Fum"
   str_capitalize "foo Fi fuM" | assert "Foo Fi FuM"
}

function str_escape {
   # Add backslashes to the following characters, .[]()*$, and return string.
   # >>> str_escape [-stdin] ["string"]
   # -stdin: Read standard input.
   ${arcRequireBoundVariables}
   if [[ "${1:-}" == "-stdin" ]]; then
      sed 's#\([]\(\)\*\.\$[]\)#\\\1#g' 
   else
      echo "${1:-}" | str_escape "-stdin"      
   fi
   ${returnTrue} 
}

function test_str_escape {
   echo 'foo.bar[]foo()bar*foo$bar' | str_escape -stdin | assert 'foo\.bar\[\]foo\(\)bar\*foo\$bar'
   str_escape 'foo.bar[]foo()bar*foo$bar' | assert 'foo\.bar\[\]foo\(\)bar\*foo\$bar'
}

function str_return_part_between_words {
   # >>> str_return_part_between_words [-defaultValue "X"] [-startWord,-s "X"] [-endWord,-e "X"] "inputStr"
   # -defaultValue: Return value if nothing else is found.
   # -startWord: Option start word, else beginning of inputStr is assumed.
   # -endWord: Optional end word, else end of inputStr is assumed.
   # inputStr: String being evaluated.
   # **Example**
   # ```
   # $ str_return_part_between_words -s "mission" -e "important" \
   # >    "This mission is too important for me to allow you to jeopardize it."
   # is too
   # ```
   ${arcRequireBoundVariables}
   typeset startWord endWord inputStr betweenWords returnStr b s defaultValue
   s=" "
   startWord=
   endWord=
   returnStr=
   b=
   defaultValue=
   while (( $# > 0)); do
      case "${1}" in
         "-startWord"|"-s")
            shift
            startWord="${1}"
            ;;
         "-endWord"|"-e")
            shift 
            endWord="${1}"
            ;;
         "-defaultValue"|"-d")
            shift 
            defaultValue="${1}"
            ;;
         "-inputStr")
            shift 
            inputStr="${1}"
            ;;
         *) break                            
            ;;
      esac
      shift
   done
   utl_raise_invalid_arg_option "str_return_part_between_words" "$*" && ${returnFalse}
   utl_raise_invalid_arg_count "str_return_part_between_words" "(( $# <= 1 ))" && ${returnFalse}
   [[ -z "${inputStr:-}" ]] && inputStr="${1}"
   [[ -z "${startWord:-}" ]] && betweenWords=1 || betweenWords=0
   while IFS= read -r x; do
      if [[ "${x}" != " " ]]; then
         b="${b}${x}"  
      else
         if (( ${betweenWords} )) && [[ "${b}" == "${endWord}" ]]; then
            betweenWords=0
            break
         elif ! (( ${betweenWords} )) && [[ "${b}" == "${startWord}" ]]; then
            betweenWords=1
         elif (( ${betweenWords} )); then
            returnStr="${returnStr} ${b}"
         fi
         b=     
      fi
   done < <(str_to_char_stream "${inputStr}${s}")
   if (( ${betweenWords} )) && [[ -n "${b}" ]]; then
      returnStr="${returnStr} ${b}"
   fi
   if [[ -n "${returnStr}" ]]; then
      echo "${returnStr}" | str_trim_line -stdin
   elif [[ -n "${defaultValue:-}" ]]; then 
      echo "${defaultValue}"
   fi
}

function test_str_return_part_between_words {
   str_return_part_between_words -startWord "push" -endWord "to" -inputStr "push" | assert -z
   str_return_part_between_words -startWord "push" -endWord "to" -inputStr "push foo" | assert "foo"
   str_return_part_between_words -startWord "to" -inputStr "push to foo" | assert "foo"
   str_return_part_between_words -startWord "to" -inputStr "push foo" | assert -z
   str_return_part_between_words -s "mission" -e "important" \
      "This mission is too important for me to allow you to jeopardize it." | assert "is too"
}

function str_len {
   # Read input or standard input and return the length of a string. 
   # >>> str_len [-stdin] ["string"]
   # string: With no "string", read STDIN. 
   #
   # **Example**
   # ```
   # $ str_len "/home/poste/Dropbox/arcshell/core"
   # 33
   # $ echo "/home/poste/Dropbox/arcshell/core" | str_len -stdin
   # 33
   # ```
   ${arcRequireBoundVariables}
   typeset x
   if [[ "${1:-}" == "-stdin" ]]; then
      while read -r x; do
         echo ${#x}
      done
   else 
      echo ${#1}
   fi
}

function test_str_len {
   str_len "abc" | assert 3
   echo "abc d" | str_len -stdin | assert 5
}

function str_center2 {
   #
   # >>> str_center2 "length" "character"
   ${arcRequireBoundVariables}
   typeset total_length spacer input_str len spacer_length
   total_length="${1}"
   spacer="${2:-" "}"
   input_str="$(cat)"
   len=$(str_len "${input_str}")
   ((spacer_length=(total_length-len)/2))
   printf "$(str_repeat "${spacer}" ${spacer_length})"
   printf "${input_str}"
   printf "$(str_repeat "${spacer}" ${spacer_length})\n"
}

function str_center {
   # Centers a string.
   # >>> str_center [-width X] [-outline] "string"
   # -width: Defaults to 80.
   # -outline: Creates a box around the text.
   # string: String to center.
   #
   # **Example**
   # ```
   # $ str_center -w 20 -o "ArcShell"
   # --------------------
   # |     ArcShell     |
   # --------------------
   #```
   ${arcRequireBoundVariables}
   typeset textString lineWidth textWidth doOutline lp rp
   lineWidth=80
   doOutline=0
   while (( $# > 0 )); do
      case $1 in
         -width|-w) shift
            lineWidth=${1}
            ;;
         -outline|-o)
            doOutline=1
            ;;
         *) 
            break                                            
            ;;
      esac
      shift
   done
   utl_raise_invalid_option "str_center" "(( $# == 1 ))" "$*" && ${returnFalse} 
   textString="${1}"
   textWidth=$(str_len "${textString}")
   if (( ${doOutline} )); then
      if (( ${textWidth}+2 >= ${lineWidth} )); then
         ((lineWidth=textWidth+2))
      fi
      str_repeat '-' ${lineWidth}
      ((lp=(lineWidth-(2+textWidth))/2))
      ((rp=lineWidth-(2+lp+textWidth)))
      echo "|$(str_repeat ' ' ${lp})${textString}$(str_repeat ' ' ${rp})|"
      str_repeat '-' ${lineWidth}
   else
      ((lp=(lineWidth-(0+textWidth))/2))
      rp=0
      echo "$(str_repeat ' ' ${lp})${textString}"
   fi
}

function test_str_center {
   echo "|$(str_center -width 9 "x")|" | assert "|    x|"
   echo "|$(str_center -width 8 "x")|" | assert "|   x|"
}

function str_to_table {
   # Formats string inputs into rows and columns.
   # >>> str_to_table [-columns "X,"] [-outline] "string" "string"
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
   # | State               | City                 |
   # ----------------------------------------------
   # | TX                  | Dallas               |
   # ----------------------------------------------
   # | CO                  | Denver               |
   # ----------------------------------------------
   # ```
   ${arcAllowUnboundVariables}
   typeset columnWidths x columnWidth columnNum maxLineCount lineCount cacheKey lineNum lineWidth d topLine w
   columnWidths="40,40"
   formatString=
   outLine=0
   topLine=0
   while (( $# > 0)); do
      case $1 in
         -outline|-o) 
            outLine=1
            ;;
         -topline|-t)
            topLine=1
            ;;
         -columns|-c) shift
            columnWidths="${1}"
            ;;
         *) 
            break                                            
            ;;
      esac
      shift
   done
   x=0
   columnCount=$(echo "${columnWidths}" | str_split_line "," | wc -l | tr -d ' ')
   lineWidth=$(echo "${columnWidths}" | str_split_line "," | num_sum -stdin)
   formatString=
   maxLineCount=0
   while read columnWidth; do
      ((x=x+1))
      cacheKey="$$-${x}"
      echo "${1}" | fold -s -w ${columnWidth} | cache_save -term 15 "${cacheKey}" 
      lineCount=$(echo "${1}" | fold -s -w ${columnWidth} | wc -l | tr -d ' ')
      (( ${lineCount} > ${maxLineCount} )) && maxLineCount=${lineCount} 
      if (( ${outLine} )); then
         formatString="${formatString}| %-${columnWidth}s"
      else
         formatString="${formatString}  %-${columnWidth}s"
      fi
      shift
   done <<< "$(echo "${columnWidths}" | str_split_line ",")"
   if (( ${outLine} )); then
      formatString="${formatString} |\n"
   else
      formatString="${formatString}  \n"
   fi
   x=
   while read lineNum; do
      while read columnNum; do
         x[${columnNum}]="$(cache_get $$-${columnNum} | sed -n "${lineNum}p")"
         #x=
         #x[${columnNum}]="$(echo ${d[${columnNum}]} | sed -n "${lineNum}p")"
      done < <(num_range 1 ${columnCount})
      if (( ${topLine} )); then
         w=$(num_floor ${lineWidth})
         ((w=w+(columnCount*2)+2))
         str_repeat "-" "${w}"
      fi
      case ${columnCount} in 
         1) printf "${formatString}" "${x[1]}" ;;
         2) printf "${formatString}" "${x[1]}" "${x[2]}" ;;
         3) printf "${formatString}" "${x[1]}" "${x[2]}" "${x[3]}";;
         4) printf "${formatString}" "${x[1]}" "${x[2]}" "${x[3]}" "${x[4]}";;
         5) printf "${formatString}" "${x[1]}" "${x[2]}" "${x[3]}" "${x[4]}" "${x[5]}";;
      esac
   done < <(num_range 1 ${maxLineCount})
   while read columnNum; do
      cache_delete "$$-${columnNum}"
   done < <(num_range 1 ${columnCount})
   if (( ${outLine} )); then
      w=$(num_floor ${lineWidth})
      ((w=w+(columnCount*2)+2))
      str_repeat "-" "${w}"
   fi
}

function test_str_to_table {
   :
}

function str_to_arg_stream {
   # Return textString as a series of lines in which each line is one of the args.
   # >>> str_to_arg_stream "textString"
   # textString: Text similar to a command line argument string.
   ${arcRequireBoundVariables}
   eval "_str_to_arg_stream "${1}""
   # _str_to_arg_stream "${1}" "${2:-}" "${3:-}" "${4:-}" "${5:-}" "${6:-}"
   #_str_to_arg_stream "$*"
}

function test_str_to_arg_stream {
   :
}

function _str_to_arg_stream {
   # Supporting function for str_to_arg_stream. Simply echos each argument to a new line.
   while (( $# > 0 )); do
      echo "${1}"
      shift
   done
}

function test__str_to_arg_stream {
   pass_test
}

function str_to_char_stream {
   # Convert textString to a series of single character lines.
   # >>> str_to_char_stream "textString"
   ${arcRequireBoundVariables}
   typeset textString i
   textString="${1:-}"
   if [[ -z "${textString}" ]]; then
      while read -r x; do
         str_to_char_stream "${x}"
      done
   else
      for (( i=0; i<${#textString}; i++ )); do
        echo "${textString:$i:1}"
      done
   fi
}

function test_str_to_char_stream {
   :
}

function str_repeat {
   # Repeat a single or multi character string N times.
   # >>> str_repeat "string" N
   # string: Character(s) to repeat.
   # N: Repeat count.
   # 
   # **Example**
   # ```
   # $ str_repeat "-" 20
   # --------------------
   # ```
   ${arcRequireBoundVariables}
   typeset x
   num_range 1 "${2}" | while read x; do
      printf "%s" "${1}"
   done
   printf "\n"
}

function test_str_repeat {
   str_repeat "a" 3 | assert "aaa"
   echo "x$(str_repeat " " 5)x" | assert "x     x"
}

function str_to_key_str {
   # Return input string after replacing most special chars with a '_'.
   # >>> str_to_key_str "string"
   ${arcRequireBoundVariables}
   if [[ -n "${1:-}" ]]; then
      echo "${1}" | str_to_key_str
   else
      tr -s '/!@#$%^&*()[]{}\^?\\/<>,.' ' ' | tr -s ' ' '_'
   fi
}

function test_str_to_key_str {
   str_to_key_str "/foo/bar/bin" | assert "_foo_bar_bin"
   echo "/foo/bar/bin" | str_to_key_str | assert "_foo_bar_bin"
}

function str_get_next_word {
   # Return the word following a word in a string of words.
   # >>> str_get_next_word "searchWord" "textString"
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
   ${arcRequireBoundVariables}
   debug3 "str_get_next_word: $*"
   typeset x lastWord currentWord searchWord
   searchWord="${1:-}"
   if [[ -n "${2:-}" ]]; then
      echo "${2}" | str_get_next_word "${searchWord}"
   else
      while read -r x; do
         lastWord=
         echo "${x}" | str_split_line " " | while read -r currentWord; do
            if [[ "${lastWord:-}" == "${searchWord}" ]]; then
               echo "${currentWord}"
               break
            fi
            lastWord="${currentWord}"
         done
      done
   fi
}

function test_str_get_next_word {
   echo "see cat run" | str_get_next_word | assert "see"
   echo "see cat run" | str_get_next_word "see" | assert "cat"
   echo "see cat run" | str_get_next_word "cat" | assert "run"
   echo "see cat run" | str_get_next_word "run" | assert -z
   echo "# from foo import *" | str_get_next_word "from" | assert "foo"
}

function str_get_word_num {
   # Return the N'th word in line.
   #
   # >>> str_get_word_num N "stringOfWords"
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
   ${arcRequireBoundVariables}
   typeset wordNum
   wordNum=${1}
   if [[ -n "${2:-}" ]]; then
      echo "${2}" | str_get_word_num "${1}"
   else
      cut -d" " -f${wordNum} 
   fi
}

function test_str_get_word_num {
   str_get_word_num 2 "x y z" | assert "y"
   echo "x y z" | str_get_word_num 2 | assert "y"
   echo "x y z" | str_get_word_num 1 | assert "x"
}

function str_get_last_word {
   # Return last word in a string or each line read from standard input.
   # >>> str_get_last_word [-stdin|"string" ]   
   ${arcRequireBoundVariables}
   typeset x
   if [[ "${1:-}" == "-stdin" ]]; then
      while read -r x; do
         echo "${x##* }"
      done
   else 
      echo "${1:-}" | str_get_last_word -stdin
   fi
}

function test_str_get_last_word {
   str_get_last_word "And the last word should be fish." | assert "fish."
   echo "The last word is beach." | str_get_last_word -stdin| assert "beach."
}

function _strReverseCatNL {
   # Called by str_reverse_cat when 'nl' is available.
   ${arcRequireBoundVariables}
   debug3 "_strReverseCatNL: $*"
   nl -b a | sort -nr | cut -f 2-
}

function _str_reverse_cat_tac {
   # Called by str_reverse_cat when 'tac' is available.
   ${arcRequireBoundVariables}
   debug3 "_str_reverse_cat_tac: $*"
   tac
}

function str_reverse_cat {
   # Returns lines in reverse order from a file or standard input.
   # >>> str_reverse_cat [-stdin] "file_name"
   #
   # **Example**
   # ```
   #  (
   # > cat <<EOF
   # > A
   # > B
   # > EOF
   # > ) | str_reverse_cat
   # B
   # A
   # ```
   ${arcRequireBoundVariables}
   debug3 "str_reverse_cat: $*"
   typeset x func
   [[ "${1:-}" == "-stdin" ]] && shift
   if (( $# == 1 )); then
      cat "${1}" | str_reverse_cat
      ${returnTrue} 
   fi
   if _is_tac_found; then
      func="_str_reverse_cat_tac"
   else
      func="_strReverseCatNL"
   fi 
   ${func}
   ${returnTrue} 
}

function test_str_reverse_cat {
   (
   cat <<EOF

a
1

z
2

EOF
   ) > "${_strTestFile}"
   cat "${_strTestFile}" | str_reverse_cat | utl_remove_blank_lines -stdin | tail -1 | assert "a"
   str_reverse_cat "${_strTestFile}" | utl_remove_blank_lines -stdin | tail -1 | assert "a"
   str_reverse_cat "${_strTestFile}" | assert -l "=7"
   $(str_is_blank_line "$(str_reverse_cat "${_strTestFile}" | tail -1)") && pass_test || fail_test
}

function str_is_blank_line {
   # Check if line is blank. Tabs, spaces and line returns are counted as blanks.
   # >>> str_is_blank_line "textString"
   #
   # **Example**
   # ```
   # textString=" "
   # $(str_is_blank_line "${textString}") && echo "Yes"
   # ```
   ${arcRequireBoundVariables}
   debug3 "str_is_blank_line: $*"
   if num_is_zero $(echo "${1:-}" | utl_remove_blank_lines -stdin | wc -l | tr -d ' '); then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_str_is_blank_line {
   str_is_blank_line "" && pass_test || fail_test
   ! str_is_blank_line " x" && pass_test || fail_test
   ! str_is_blank_line " x " && pass_test || fail_test
   str_is_blank_line $(printf "\t\n") && pass_test || fail_test 
   str_is_blank_line $(printf " \t\n\n") && pass_test || fail_test 
   str_is_blank_line "   " && pass_test || fail_test "Blank spaces should be evaluated as a blank line."
}

function str_remove_leading_blank_lines {
   # Remove leading blank lines from a file or standard input.
   # >>> str_remove_leading_blank_lines "${file_name}"
   #
   # **Example**
   # ```
   # str_remove_leading_blank_lines /tmp/example.txt
   # cat /tmp/example.txt | str_remove_leading_blank_lines
   # ```
   ${arcRequireBoundVariables}
   debug3 "str_remove_leading_blank_lines: $*"
   if [[ -n "${1:-}" ]]; then
      cat "${1}" | str_remove_leading_blank_lines
   else
      sed '/./,$!d'
   fi
}

function test_str_remove_leading_blank_lines {
   (
   cat <<EOF

a
1

z
2

EOF
   ) > "${_strTestFile}"
   str_remove_leading_blank_lines "${_strTestFile}" | assert -l "=6"
   str_remove_leading_blank_lines "${_strTestFile}" | head -1 | assert "a"
   cat "${_strTestFile}" | str_remove_leading_blank_lines | assert -l "=6"
   cat "${_strTestFile}" | str_remove_leading_blank_lines | head -1 | assert "a"
}

function str_to_csv {
   # Return a comma separated line to standard output
   #
   # >>> str_to_csv ["delimiter"]
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
   ${arcRequireBoundVariables}
   typeset x csvText delimiter 
   csvText=
   delimiter="${1:-","}"
   while read -r x; do
      csvText="${csvText}$(printf "${x}${delimiter}")"
   done
   [[ -n "${csvText:-}" ]] && echo "${csvText}" | sed 's/.$//g' | utl_remove_blank_lines -stdin
}

function test_str_to_csv {
   (
cat <<EOF
a@a.com,b@b.com
c@c.com
EOF
   ) | str_to_csv | assert "a@a.com,b@b.com,c@c.com"
}

function str_get_last_char {
   # Return last character in a ```string```.
   # >>> str_get_last_char [-stdin|"string"]
   ${arcRequireBoundVariables}
   if [[ "${1:-}" == "-stdin" ]]; then
      ${arcAwkProg} '{print substr($0,length,1)}'
   else
      echo "${1}" | str_get_last_char -stdin
   fi
}

function test_str_get_last_char {
   str_get_last_char "AzZ" | assert "Z"
   str_get_last_char "a1 2b" | assert "b"
   printf "AzZ\n" | str_get_last_char -stdin | assert "Z"
   printf "\n" | str_get_last_char -stdin | assert -l "=1"
   cp /dev/null "${_strTestFile}"
   cat "${_strTestFile}" | str_get_last_char -stdin | assert -z
}

function str_reverse_line {
   # Reverse the characters ```string```.
   # >>> str_reverse_line [-stdin|"string"]
   ${arcRequireBoundVariables}
   if [[ "${1:-}" == "-stdin" ]]; then
      ${arcAwkProg} '{ for(i=length;i!=0;i--)x=x substr($0,i,1);}END{print x}'
   else
      echo "${1}" | str_reverse_line -stdin
   fi
}

function test_str_reverse_line {
   [[ $(echo "abc [abc] *abc! #abc% &abc( (abc)" | str_reverse_line -stdin) == ")cba( (cba& %cba# !cba* ]cba[ cba" ]] && pass_test || fail_test
   [[ $(str_reverse_line "abc [abc] *abc! #abc% &abc( (abc)") == ")cba( (cba& %cba# !cba* ]cba[ cba" ]] && pass_test || fail_test
}

function str_trim_line {
   # Remove leading and trailing blanks from a ```string```.
   # >>> str_trim_line [-stdin|"string"]
   ${arcRequireBoundVariables}
   debug3 "str_trim_line: $*"
   typeset x
   if [[ "${1:-}" == "-stdin" ]]; then
      while read -r x; do
         # echo "${x}" | sed -e 's/^ *//' -e 's/ *$//'
         echo "${x}"
      done
   else
      echo "${1:-}" | str_trim_line -stdin
   fi
}

function test_str_trim_line {
   [[ $(echo "  foo foo  ") == "  foo foo  " ]] && pass_test || fail_test
   [[ $(echo "  foo foo  " | str_trim_line -stdin) == "foo foo" ]] && pass_test || fail_test
   [[ $(str_trim_line "  foo foo  ") == "foo foo" ]] && pass_test || fail_test
}

function str_get_char_count {
   # Return the number of times a character appears in a string.
   # >>> str_get_char_count [-stdin] "character" ["string"]
   ${arcRequireBoundVariables}
   if [[ "${1:-}" == "-stdin" ]]; then
      tr -d -c "${2}" | wc -c
   else
      echo "${2:-}" | str_get_char_count -stdin "${1}"
   fi
}

function test_str_get_char_count {
   echo "" | str_get_char_count -stdin "b" | assert 0
   echo "abcdabcd" | str_get_char_count -stdin "b"| assert 2
   str_get_char_count "a" "abcxyzabc" | assert 2
}

function str_split_line {
   # Read standard in and split into separate lines using a token.
   # >>> str_split_line [-stdin] "token"
   # token: Character to split on. Default is comma. A space is acceptable.
   ${arcRequireBoundVariables}
   debug3 "str_split_line: $*"
   typeset token
   # This function only supports stdin, so we just shift and ignore if the option is present.
   [[ "${1:-}" == "-stdin" ]] && shift
   token="${1:-","}"
   tr "${token}" '\n' 
}

function test_str_split_line {
   echo "a,b,c" | str_split_line -stdin "," | assert -l "=3"
   echo "a : b : c" | str_split_line ":" | assert -l "=3"
}

function str_to_upper_case {
   # Converts 'string' to upper-case.
   # >>> str_to_upper_case [-stdin|"string"]
   ${arcRequireBoundVariables}
   if [[ "${1:-}" == "-stdin" ]]; then
      tr '[:lower:]' '[:upper:]'
   else
      echo "${1}" | str_to_upper_case -stdin
   fi
}

function test_str_to_upper_case {
   echo "a,b,c" | str_to_upper_case -stdin | assert "A,B,C"
   str_to_upper_case "a,b,c" | assert "A,B,C"
}

function str_is_upper_case {
   # Return true if ```string``` is upper-case.
   # >>> str_is_upper_case "string"
   ${arcRequireBoundVariables}
   typeset x 
   x="${1:-}"
   if [[ -n "${x:-}" ]] && [[ "${x:-}" == "$(str_to_upper_case "${x}")" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_str_is_upper_case {
   str_is_upper_case "FOO" && pass_test || fail_test
   ! str_is_upper_case "Foo" && pass_test || fail_test
   str_is_upper_case "FOO BAR" && pass_test || fail_test
   ! str_is_upper_case "FOO bar" && pass_test || fail_test
}

function str_to_lower_case {
   # Convert ```string``` to lower-case.
   # >>> str_to_lower_case [-stdin|"string"]
   ${arcRequireBoundVariables}
   if [[ "${1:-}" == "-stdin" ]]; then
      tr '[:upper:]' '[:lower:]'
   else
      echo "${1:-}" | str_to_lower_case -stdin
   fi
}

function test_str_to_lower_case {
   echo "A,B,C" | str_to_lower_case -stdin | assert "a,b,c"
   str_to_lower_case "A,B,C" | assert "a,b,c"
}

function str_is_lower_case {
   # Return true if the ```string``` is lower-case.
   # >>> str_is_lower_case "string"
   ${arcRequireBoundVariables}
   typeset x 
   x="${1}"
   if [[ -n "${x}" ]] && [[ "${x}" == "$(str_to_lower_case "${x}")" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_str_is_lower_case {
   str_is_lower_case "foo" && pass_test || fail_test
   ! str_is_lower_case "FOO" && pass_test || fail_test
   str_is_lower_case "foo bar" && pass_test || fail_test
   ! str_is_lower_case "FOO bar" && pass_test || fail_test
}

function str_is_word_in_list {
   # Return true if ```word`` is found in ```list```.
   # >>> str_is_word_in_list "word" "list"
   # word: Word to search for.
   # list: List of words separated by spaces or a comma.
   ${arcRequireBoundVariables}
   typeset w x
   w="${1}"
   x=$(echo "${2}" | str_split_line "," | tr '.!;:' ' ' | str_trim_line -stdin | grep "^${w}$" | wc -l | tr -d ' ')
   if (( ${x} )); then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_str_is_word_in_list {
   # $(str_is_word_in_list "foo" "fee fi fo fum foo") && pass_test || fail_test
   # $(str_is_word_in_list "foo" "foo fi fo fum") && pass_test || fail_test
   # $(str_is_word_in_list "foo" "fi foo fum") && pass_test || fail_test
   # ! $(str_is_word_in_list "foo" "fee fi fo fum xfoo") && pass_test || fail_test
   # ! $(str_is_word_in_list "foo" "foox fi fo fum") && pass_test || fail_test
   ! str_is_word_in_list "foo" "fi xfoo fum" && pass_test || fail_test
   str_is_word_in_list "foo" "fee,fi,fo,fum,foo" && pass_test || fail_test
   str_is_word_in_list "foo" "foo,fi,fo,fum" && pass_test || fail_test
   str_is_word_in_list "foo" "fi,foo,fum" && pass_test || fail_test
}

function str_instr {
   # Return position of ```str``` within ```string```.
   # >>> str_instr "str" "string"
   # str: String to search for.
   # string: String to search.
   typeset str string x
   # Behavior here is not the same in bash vs ksh unless we escape special characters.
   if [[ -n "${1:-}" ]]; then
      str="$(str_escape "${1:-}")"
   else
      str="${1}"
   fi
   string="${2}"
   x="${string%%$str*}"
   if [[ "${x}" != "${string}" ]]; then
      echo "${#x} + 1" | bc -l
      ${returnTrue} 
   else
      echo 0
      ${returnFalse} 
   fi
}

function test_str_instr {
   str_instr "(" "'foo@host (dev,web)'" | assert 11
   str_instr ")" "'foo@host (dev,web)'" | assert 19
   str_instr "[" "'foo@host [dev,web]'" | assert 11
   str_instr "]" "'foo@host [dev,web]'" | assert 19
   str_instr "a" "abc" | assert 1
   str_instr "z" "abc" | assert 0
   str_instr "Eggs" "Green Eggs And Ham" | assert 7
   str_instr "a" "" | assert 0
   str_instr "" "" | assert 0
   str_instr " " "Green Eggs" | assert 6
   str_instr " " " Green "  | assert 1
}

function str_replace_tabs_with_space {
   # Replace tab characters in ```string``` with a single space.
   # >>> str_replace_tabs_with_space [-stdin|"string"]
   ${arcRequireBoundVariables}
   debug2 "str_replace_tabs_with_space: $*"
   if [[ "${1:-}" == "-stdin" ]]; then
      #sed "s/\t/ /g"
      tr '\011' ' '
   else
      echo "${1:-}" | str_replace_tabs_with_space -stdin
   fi
}

function test_str_replace_tabs_with_space {
   printf "\t Tab \t\n" | str_replace_tabs_with_space -stdin | assert "  Tab  "
   str_replace_tabs_with_space "$(printf "\t Tab \t\n")" | assert "  Tab  "
}

function str_replace_end_of_line_with_slash_n {
   # Returns input and replaces line endings with literal "\n". Used for JSON data primarily.
   # >>> str_replace_end_of_line_with_slash_n [-stdin|"file"]
   ${arcRequireBoundVariables}
   if [[ "${1:-}" == "-stdin" ]]; then
      awk '{printf "%s\\n", $0}'
   else
      cat "${1:-}" | str_replace_end_of_line_with_slash_n -stdin
   fi
}

function str_remove_spaces {
   # Remove spaces from ```string```.
   # >>> str_remove_spaces [-stdin|"string"]
   ${arcRequireBoundVariables}
   if [[ "${1:-}" == "-stdin" ]]; then
      sed 's/ //g'
   else
      echo "${1:-}" | str_remove_spaces -stdin
   fi
}

function test_str_remove_spaces {
   echo "foo ba r " | str_remove_spaces -stdin | assert "foobar"
   str_remove_spaces " foo bar " | assert "foobar"
}

function str_remove_double_spaces {
   # Replace double spaces in ```string``` with single spaces.
   # >>> str_remove_double_spaces [-stdin|"string"]
   # Todo: Better name.
   ${arcRequireBoundVariables}
   if [[ "${1:-}" == "-stdin" ]]; then
      tr -s " "
   else
      echo "${1:-}" | str_remove_double_spaces -stdin
   fi
}

function test_str_remove_double_spaces {
   echo "f  o   o  " | str_remove_double_spaces -stdin | assert "f o o "
}

function str_remove_control_m {
   # Remove Control ^M characters from ```string```.
   # >>> str_remove_control_m [-stdin|"string"]
   ${arcRequireBoundVariables}
   if [[ "${1:-}" == "-stdin" ]]; then
      tr -d '\015'
   else
      echo "${1:-}" | str_remove_control_m -stdin
   fi
}

function test_str_remove_control_m {
   :
}

function str_remove_ticks_and_quotes {
   # Remove single ticks and double quote characters from input. 
   # >>> str_remove_ticks_and_quotes [-stdin|"string"]
   ${arcRequireBoundVariables}
   if [[ "${1:-}" == "-stdin" ]]; then
      sed -e "s/'//g" -e 's/"//g'
   else
      echo "${1:-}" | str_remove_ticks_and_quotes -stdin
   fi
}

function test_str_remove_ticks_and_quotes {
   echo "'foo'" | str_remove_ticks_and_quotes -stdin | assert "foo"
   str_remove_ticks_and_quotes "'a','b'" | assert "a,b"
}

function str_is_key_str {
   # Return true if string is a key string.
   # >>> str_is_key_str "string"
   # string: Key strings are restricted to "a-z", "0-9", "A-Z", "-". ".", and "_".
   ${arcRequireBoundVariables}
   typeset str
   str="$(echo "${1}" | sed "s/[A-Z|a-z|0-9|\_|-]//g;" | sed "s/\.//g")"
   if [[ -z "${str}" && -n "${1}" ]]; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test_str_is_key_str {
   str_is_key_str "yes._-yes" && pass_test || fail_test
   ! str_is_key_str "yes yes" && pass_test || fail_test
   ! str_is_key_str "" && pass_test || fail_test
}

function str_raise_not_a_key_str {
   # Throws an error and return true if the provided string is not a key string.
   # >>> str_raise_not_a_key_str ["source_of_call"] "string" 
   # source_of_call: A string which usually identifies the caller.
   # string: Key strings are restricted to "a-z", "0-9", "A-Z", "-". ".", and "_".
   ${arcRequireBoundVariables}
   typeset str source_of_call
   if (( $# == 1 )); then
      source_of_call=""
      str="${1:-}"
   else
      source_of_call="${1}"
      str="${2:-}"
   fi
   if [[ -z "${str:-}" ]] ||  ! str_is_key_str "${str}"; then
      _strThrowError "Not a key string. Restrict to "a-z", "0-9", "A-Z", "-". ".", and "_" characters: ${str}: ${source_of_call:-}"
      ${returnTrue}
   else
      ${returnFalse}      
   fi
}

function test_str_raise_not_a_key_str {
   ! str_raise_not_a_key_str "foo" && pass_test || fail_test 
   str_raise_not_a_key_str "test_caller" "foo+" && pass_test || fail_test 
}

function _is_tac_found {
   # Determine if tac is found in ${PATH}.
   #
   # > Avoid calling tac directly, not posix compliant. Use 
   # > str_reverse_cat and it will work even when tac is not available.
   #
   # >>> _is_tac_found
   #
   # **Example**
   # ```
   # $(_is_tac_found) && echo "Yes"
   # ```
   if boot_is_program_found "tac"; then
      ${returnTrue}
   else
      ${returnFalse}
   fi
}

function test__is_tac_found {
   _is_tac_found && which tac | assert_match "tac"
   ! _is_tac_found && which tac 2> /dev/null | assert -z 
}

function _strThrowError {
   # Error handler for this library.
   # >>> _strThrowError "errorText"
   throw_error "arcshell_str.sh" "${1}"
}

