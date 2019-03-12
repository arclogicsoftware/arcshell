

BEGIN {
   FS=" "
}

{
   pid=$1
   time=$2
   user=$3
   comm=$4$5$6$7$8$9$10
   split_count=split($2,days_array,"\-")
   if ( split_count == 2 ) {
      days=days_array[1]
      hr_min_sec=days_array[2]
   }
   else {
      days=0
      hr_min_sec=days_array[1]
   }
   split_count=split(hr_min_sec,hr_min_sec_array,":")
   if ( split_count == 3 ) {
      hours=hr_min_sec_array[1]
      minutes=hr_min_sec_array[2]
      seconds=hr_min_sec_array[3]
   }
   else if ( split_count == 2 ) {
      hours=0
      minutes=hr_min_sec_array[1]
      seconds=hr_min_sec_array[2]
   }
   else if ( split_count == 1 ) {
      hours=0
      minutes=0
      seconds=hr_min_sec_array[1]
   }
   total_seconds=(days*24*60*60)+(hours*60*60)+(minutes*60)+(seconds)
   print pid"|"total_seconds"|"user"|"comm
}

