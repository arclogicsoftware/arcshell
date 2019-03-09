
# Sample
# 1544070079|server_load|2018|12|5|22|21|19|1|3|value|65|os,server_load|server_load|Value|4.00|Avg|1.28|%OfAvg|312|AvgByDayType|1.28|%OfAvgByDayType|312|AvgByHour|-100.00|%OfAvgByHour|-100

BEGIN {
   FS="|";
   pct_avg_value=""
   index_number=0
}

{  
   i="-|"$2"|"$3"|"$4"|"$5"|"$6"|-|-|"$9"|"$10"|"$11"|-|"$13"|"$14
   # This is being used to preserve the order of the output.
   if (!(i in metricValueSum)) {
      index_number+=1
      ordered_index[index_number]=i
   }
   metricValueSum[i]+=$16
   metricValueCount[i]+=1
   metricElapsedSeconds[i]+=$12
   if ( $28 >= 0 ) {
      pct_avg_value=$28
   }
   else if ( $24 >= 0 ) {
      pct_avg_value=$24
   }
   else if ( $20 >= 0 ) {
      pct_avg_value=$20
   }
   pctAvgValueSum[i]+=pct_avg_value 
   pctAvgValueCount[i]+=1   
   totalElapsedSeconds[i]+=$12
   if ( pct_avg_value <= 10 ) {
      timeBucket1[i]+=$12
      secondsOver[i]+=0
      score[i]+=0
   }
   else if ( pct_avg_value <= 100 ) {
      timeBucket2[i]+=$12
      secondsOver[i]+=0
      score[i]+=1
   }
   else if ( pct_avg_value <= 120 ) {
      timeBucket3[i]+=$12
      totalScore[i]+=1
      secondsOver[i]+=0
      score[i]+=2
   }
   else if ( pct_avg_value <= 200 ) {
      timeBucket4[i]+=$12
      totalScore[i]+=2
      secondsOver[i]+=$12
      score[i]+=4
   }
   else if ( pct_avg_value <= 500 ) {
      timeBucket5[i]+=$12
      totalScore[i]+=5
      secondsOver[i]+=$12
      score[i]+=8
   }
   else if ( pct_avg_value <= 1000 ) {
      timeBucket6[i]+=$12
      totalScore[i]+=10
      secondsOver[i]+=$12
      score[i]+=16
   }
   else {
      timeBucket7[i]+=$12
      totalScore[i]+=20
      secondsOver[i]+=$12
      score[i]+=32
   }
   # if ( score[i] <=5 ) {
   #    scoreR[i]=0
   # }
   # else {
   #    scoreR[i]=score[i]
   # }
   currentScore[i]=totalScore[i]/metricValueCount[i]
   metricValueTimeSum[i]+=$12
}

END {
   # for (x in metricValueCount) 
   i=1
   while ( i <= index_number)
   {
      x=ordered_index[i]
      #        1| 2|   3| 4|   5| 6|   7| 8|   9|10|  11|12|  13|14|  15|16|  17|18|  19|20|  21|22|  23|24|  25|26|  27
      printf "%s|%s|%.2f|%s|%.0f|%s|%.0f|%s|%.0f|%s|%.0f|%s|%.0f|%s|%.0f|%s|%.0f|%s|%.0f|%s|%.0f|%s|%0.f|%s|%.0f|%s|%.0f\n", \
         # 1
         x, \
         "AvgValue", \
         metricValueSum[x]/metricValueCount[x], \
         "%OfAvgValue", \
         # 5
         pctAvgValueSum[x]/pctAvgValueCount[x], \
         "'<=10%'", \
         timeBucket1[x]/totalElapsedSeconds[x]*100, \
         "'11%-100%'", \
         timeBucket2[x]/totalElapsedSeconds[x]*100, \
         # 10
         "'101%-120%'", \
         timeBucket3[x]/totalElapsedSeconds[x]*100, \
         "'121%-200%'", \
         timeBucket4[x]/totalElapsedSeconds[x]*100, \
         "'201%-500%'", \
         # 15
         timeBucket5[x]/totalElapsedSeconds[x]*100, \
         "'501%-1000%'", \
         timeBucket6[x]/totalElapsedSeconds[x]*100, \
         "''>1000%'", \
         timeBucket7[x]/totalElapsedSeconds[x]*100, \
         # 20
         "#OfDataPoints", \
         metricValueCount[x], \
         "AvgSecsBetweenDataPoints", \
         metricElapsedSeconds[x]/metricValueCount[x], \
         "minutesOver", \
         # 25
         int(secondsOver[x]/60),
         "Score", \
         #int(currentScore[x]*10)
         int(score[x]/metricValueCount[x])
      i+=1
   }
}


