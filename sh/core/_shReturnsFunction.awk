


BEGIN {
   will_write=0
}

{
   if ( $1 == "function" && $2 ~ regex ) {
      will_write=1
      }
   else if ( will_write == 1 && $1 == "}" ) {
      will_write=0
      print $0
   }
   if ( will_write == 1 ) {
      print $0
   }
}

