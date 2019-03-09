
function print_func_name (func_name) {
   if ( ! synopsisOnly ) {
      print_blank_line()
      if ( vType == "markdown" ) {
         print "### "func_name
      }
      else {
         print func_name
         print "----------------------------------------"
      }
   }
}

function print_func_short_desc (short_desc) {
   if ( ! synopsisOnly ) {
      sub(/^[ \t]+/, "", short_desc)
      if ( vType == "markdown" ) {
         print short_desc
      }
      else {
         print short_desc
      }
   }
}

function print_func_long_desc (long_desc) {
   if ( ! synopsisOnly ) {
      sub(/^[ \t]+/, "", long_desc)
      if ( vType == "markdown" ) {
         print long_desc
      }
      else {
         #if ( longDescLine == 1 ) {
            #print_blank_line()
         #}
         print "| "long_desc
      }
   }
}

function print_func_synopsis (synopsis) {
   sub(/^[ \t]+/, "", synopsis)
   if ( vType == "markdown" ) {
      print "```bash"
      print "> "synopsis
   }
   else {
      if ( synopsisOnly ) {
         print "> "synopsis
      }
      else {
         #print_blank_line()
         print "> "synopsis
      }
   }
}

function print_arg_desc (arg_number, arg_text) {
   if ( ! synopsisOnly ) {
      sub(/^[ \t]+/, "", arg_text)
      if ( vType == "markdown" ) {
         print "# "arg_text
      }
      else {
         #if ( synopsisLine == 1 ) {
            #print_blank_line()
         #}
         print "["arg_number"] "arg_text
      }
   }
}

function print_end_of_last_func () {
   if ( vType == "markdown" ) {
      if ( synopsisLine > 0 ) {
         print "```"
      }
   }
}

function print_blank_line () {
   print ""
}

BEGIN {
   FS=" ";
   docLine=0;
   #includePrivateFunctions=1
   #includePublicFunctions=1
   #synopsisOnly=0
   #vType=
}

{
   if ( $1 == "function" && $2 !~ /^test_/ && $2 !~ /^__/ ) {
      if ( ( includePublicFunctions && $2 !~ /^_/ ) || ( includePrivateFunctions && $2 ~ /^_/ ) ) {
         print_end_of_last_func()
         functionName=$2
         docLine=1
         synopsisLine=0
         shortDescLine=0
         longDescLine=0
         print_func_name($2)
      }
   }
   else if ( docLine > 0 ) {
      if ( $1 ~ /^ *#/ )  {
         if ( $2 ~ />>>/ ) { 
            $1=""
            $2=""
            print_func_synopsis($0)
            docLine++ 
            synopsisLine=1
         }
         else if ( synopsisLine > 0 ) {
            $1=""
            print_arg_desc(synopsisLine,$0)
            synopsisLine++
         }
         else if ( docLine == 1 ) {
            $1=""
            print_func_short_desc($0)
            docLine++ 
            longDescLine++
         }
         else {
            $1=""
            print_func_long_desc($0)
            docLine++ 
            longDescLine++
         }
      }
      else {
         docLine=0
      }
   }
}

END {
   print_end_of_last_func()
}


