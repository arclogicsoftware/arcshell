
BEGIN {
   FS = ",";
}

{

   # Input can contain up to 4 fields. Index is determined by the number.
   # The value is always the last field, it can be a number or a sign+number.
   gsub(/, +/,",",$0)
   gsub(/ +,/,",",$0)
   if ( NF == 4 ) {
      i=$1","$2","$3
      m=$4
   }
   else if ( NF == 3 ) {
      i=$1","$2
      m=$3
   }
   else {
      i=$1
      m=$2
   }
   # Get sign if it is present.
   o=substr(m,1,1)
   # Get number, assumes sign is present.
   v=substr(m,2)
   if ( o == "=" ) {
      counterTotal[i]=v
   }
   else if ( o == "-" ) {
      counterTotal[i]-=v
   }
   else if ( o == "+" ) {
      counterTotal[i]+=v
   }
   else {
      # If no sign is present assume "="
      counterTotal[i]=m
   }
}

END {       
for (x in counterTotal)
   printf "%s,=%.0f\n", x, counterTotal[x]
}

