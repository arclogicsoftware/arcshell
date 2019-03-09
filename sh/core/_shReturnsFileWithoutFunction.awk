


BEGIN {
   skip_once=0
   will_write=1
}

{
   skip_once=0
   if ( $1 == "function" && $2 ~ regex ) {
      will_write=0
      if ( stub == 1 ) {
         print "function "$2 " {\n   :\n}\n"
      }
      }
   else if ( will_write == 0 && $1 == "}" ) {
      will_write=1
      skip_once=1
   }
   if ( will_write == 1 && skip_once == 0 ) {
      print $0
   }
}

