
BEGIN {
   FS="|";
   last_epoch=-1
   value=""
   rollup_time=""
   stat_calc=""
   avg_val_prefix=""
   avg_val_by_day_type_prefix=""
   avg_val_by_day_type_and_hour_prefix=""
   avg_val=""
   avg_val_pct=""
   avg_val_by_day_type=""
   avg_val_by_day_type_pct=""
   avg_val_by_day_type_and_hour=""
   avg_val_by_day_type_and_hour_pct=""
}

{
   value=""
   textual_value=""
   # "+" means this is one of the averages record.
   # +|vmstats|-|-|-|-|-|-|0|-|value|-|-|10_bo|13.77
   if ( $1 == "+" ) {
      # Cache the record in an array.
      avgs_array[$1"|"$2"|"$3"|"$4"|"$5"|"$6"|"$7"|"$8"|"$9"|"$10"|"$11"|"$12"|"$13"|"$14]=$16
   }
   # ">" means this is the header record. Used to get elapsed seconds.
   # >|1543675831|2018|12|1|8|50|31|0|6|total_cpu_seconds|delta
   else if ( $1 == ">" ) {
      rollup_time=$3"|"$4"|"$5"|"$6"|"$7"|"$8"|"$9"|"$10
      stat_group=$11
      stat_calc=$12
      # The look-up key will need to look like this...
      # +|vmstats|-|-|-|-|-|-|0|-|value|-|-|7_si
      # We can't get the full key now since we don't have the metric at this point.
      # So we will build this...
      # +|vmstats|-|-|-|-|-|-|-|-|value|-|-
      avg_val_prefix="+|"$11"|-|-|-|-|-|-|-|-|"$12"|-|-"
      # +|vmstats|-|-|-|-|-|-|0|-|value|-|-|
      avg_val_by_day_type_prefix="+|"$11"|-|-|-|-|-|-|"$9"|-|"$12"|-|-"
      # +|vmstats|-|-|-|8|-|-|0|-|value|-|-
      avg_val_by_day_type_and_hour_prefix="+|"$11"|-|-|-|"$10"|-|-|"$9"|-|"$12"|-|-"
      if ( last_epoch != -1 ) {
         elapsed_seconds=$2-last_epoch
      }
      else {
         elapsed_seconds=0
      }
      last_epoch=$2
   }
   # This is the raw "metric|value" data.
   else {
      if ( stat_calc == "value" ) {
         value=$2
      }
      else {
         prior_value_of[$1]=last_value_of[$1]
         # Calculated deltas only work if we have two values to work with.
         if (length(prior_value_of[$1]) > 0) {
            delta=$2-prior_value_of[$1]
            value=delta
         }
         last_value_of[$1]=$2
      }
      if ( stat_calc == "per/sec" && elapsed_seconds > 0 ) {
         value=delta/elapsed_seconds
      }
      else if ( stat_calc == "per/min" && elapsed_seconds > 0 ) {
         value=delta/elapsed_seconds/60
      }
      else if ( stat_calc == "per/hr" && elapsed_seconds > 0 ) {
         value=delta/elapsed_seconds/60/60
      }
   }  
   if ( length(value) > 0 ) {
      if ( length(max_value[$1]) > 0 ) {
         if ( max_value[$1] < value ) {
            max_value[$1]=value
         }
      }
      else {
         max_value[$1]=value
      }
      avg_val_pct=-100
      avg_val=-100
      avg_text="-"
      if ( avg_val_prefix"|"$1 in avgs_array ) {
         avg_val=avgs_array[avg_val_prefix"|"$1]
         if ( avg_val != 0 ) {
            avg_val_pct=value/avg_val*100
         }
         else if ( avg_val == 0 && value == 0 ) {
            avg_val_pct=0
         }
      }
      avg_val_by_day_type_pct=-100
      avg_val_by_day_type=-100
      if ( avg_val_by_day_type_prefix"|"$1 in avgs_array ) {
         avg_val_by_day_type=avgs_array[avg_val_by_day_type_prefix"|"$1]
         if ( avg_val_by_day_type != 0 ) {
            avg_val_by_day_type_pct=value/avg_val_by_day_type*100
         }
         else if ( avg_val_by_day_type == 0 && value == 0 ) {
            avg_val_by_day_type_pct=0
         }
      }
      avg_val_by_day_type_and_hour_pct=-100
      avg_val_by_day_type_and_hour=-100
      if ( avg_val_by_day_type_and_hour_prefix"|"$1 in avgs_array ) {
         avg_val_by_day_type_and_hour=avgs_array[avg_val_by_day_type_and_hour_prefix"|"$1]
         if ( avg_val_by_day_type_and_hour != 0 ) {
            avg_val_by_day_type_and_hour_pct=value/avg_val_by_day_type_and_hour*100
         }
         else if ( avg_val_by_day_type_and_hour == 0 && value == 0 ) {
            avg_val_by_day_type_and_hour_pct=0
         }
      }
      #        1| 2| 3| 4| 5| 6| 7| 8|   9|10|  11|12|  13|14|  15|16|  17|18|  19|20|  21
      printf "%s|%s|%s|%s|%s|%s|%s|%s|%.2f|%s|%.2f|%s|%.0f|%s|%.2f|%s|%.0f|%s|%.2f|%s|%.0f\n", \
         # 1
         last_epoch, \
         stat_group, \
         rollup_time, \
         stat_calc, \
         # 5
         elapsed_seconds, \
         tags, \
         $1, \
         "Value", \
         value, \
         # 10 
         "Avg", \
         avg_val, \
         "%OfAvg", \
         avg_val_pct, \
         "AvgByDayType", \
         # 15
         avg_val_by_day_type, \
         "%OfAvgByDayType", \
         avg_val_by_day_type_pct, \
         "AvgByHour", \
         avg_val_by_day_type_and_hour, \
         # 20
         "%OfAvgByHour", \
         avg_val_by_day_type_and_hour_pct
   }
}

