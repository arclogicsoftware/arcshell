
{
   if ( $1 != "function" && $0 ~ /debug[0-4] |debugd[0-4]/ ) {
   	foo=0
   	}
   else {
      print $0
   }
}

