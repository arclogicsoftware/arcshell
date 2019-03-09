
# Sample
# -|server_load|2018|12|10|22|-|-|1|1|value|-|os,server_load|server_load|AvgValue|1.54|%OfAvgValue|92|'<=10%'|0|'11%-100%'|78|'101%-120%'|12|'121%-200%'|10|'201%-500%'|0|'501%-1000%'|0|''>1000%'|0|#OfDataPoints|59|AvgSecsBetweenDataPoints|60|MaxScore|0.06|EndingScore|0.00

BEGIN {
   FS="|";
}

{  
   # Averages For Metric
   i="+|"$2"|-|-|-|-|-|-|-|-|"$11"|-|-|"$14
   metricSum[i]+=$16
   metricDataPointSum[i]+=$24
   metricCount[i]+=1
   sum0_10pct[i]+=$20
   sum11_100pct[i]+=$22
   sum101_120pct[i]+=$24
   sum121_200pct[i]+=$26
   sum201_500pct[i]+=$28
   sum501_1000pct[i]+=$30
   sum1001_0000pct[i]+=$32
   # Weekday/Weekend Averages For Metric
   t="+|"$2"|-|-|-|-|-|-|"$9"|-|"$11"|-|-|"$14
   metricDaySum[t]+=$16
   metricDayCount[t]+=1
   metricDayDataDataPointSum[t]+=$24
   sum0_10pctDay[t]+=$20
   sum11_100pctDay[t]+=$22
   sum101_120pctDay[t]+=$24
   sum121_200pctDay[t]+=$26
   sum201_500pctDay[t]+=$28
   sum501_1000pctDay[t]+=$30
   sum1001_0000pctDay[t]+=$32
   # Weekday/Weekend Average For Metric By Hour Of Day
   v="+|"$2"|-|-|-|"$6"|-|-|"$9"|-|"$11"|-|-|"$14
   metricDayHourSum[v]+=$16
   metricDayHourCount[v]+=1
   metricDayHourDataPointSum[v]+=$24
   sum0_10pctHour[v]+=$20
   sum11_100pctHour[v]+=$22
   sum101_120pctHour[v]+=$24
   sum121_200pctHour[v]+=$26
   sum201_500pctHour[v]+=$28
   sum501_1000pctHour[v]+=$30
   sum1001_0000pctHour[v]+=$32
}

END {
   for (x in metricCount) 
   {
      printf "%s|%s|%.2f|%s|%.2f|%s|%.2f|%s|%.2f|%s|%.2f|%s|%.2f|%s|%.2f|%s|%.2f\n", \
         x, \
         "AvgValue", \
         metricSum[x]/metricCount[x],
         "'<=10%'", \
         sum0_10pct[x]/metricCount[x],
         "'11%-100%'", \
         sum11_100pct[x]/metricCount[x],
         "'101%-120%'", \
         sum101_120pct[x]/metricCount[x],
         "'121%-200%'", \
         sum121_200pct[x]/metricCount[x],
         "'201%-500%'", \
         sum201_500pct[x]/metricCount[x],
         "'501%-1000%'", \
         sum501_1000pct[x]/metricCount[x],
         "'>1000%'", \
         sum1001_0000pct[x]/metricCount[x]
   }
   for (x in metricDayCount) 
   {
      printf "%s|%s|%.2f|%s|%.2f|%s|%.2f|%s|%.2f|%s|%.2f|%s|%.2f|%s|%.2f|%s|%.2f\n", \
         x, \
         "AvgValueByDayType", \
         metricDaySum[x]/metricDayCount[x],
         "'<=10%'", \
         sum0_10pctDay[x]/metricDayCount[x],
         "'11%-100%'", \
         sum11_100pctDay[x]/metricDayCount[x],
         "'101%-120%'", \
         sum101_120pctDay[x]/metricDayCount[x],
         "'121%-200%'", \
         sum121_200pctDay[x]/metricDayCount[x],
         "'201%-500%'", \
         sum201_500pctDay[x]/metricDayCount[x],
         "'501%-1000%'", \
         sum501_1000pctDay[x]/metricDayCount[x],
         "'>1000%'", \
         sum1001_0000pct[x]/metricDayCount[x]
   }
   for (x in metricDayHourCount) 
   {
      printf "%s|%s|%.2f|%s|%.2f|%s|%.2f|%s|%.2f|%s|%.2f|%s|%.2f|%s|%.2f|%s|%.2f\n", \
         x, \
         "AvgValueByHour", \
         metricDayHourSum[x]/metricDayHourCount[x],
         "'<=10%'", \
         sum0_10pctHour[x]/metricDayHourCount[x],
         "'11%-100%'", \
         sum11_100pctHour[x]/metricDayHourCount[x],
         "'101%-120%'", \
         sum101_120pctHour[x]/metricDayHourCount[x],
         "'121%-200%'", \
         sum121_200pctHour[x]/metricDayHourCount[x],
         "'201%-500%'", \
         sum201_500pctHour[x]/metricDayHourCount[x],
         "'501%-1000%'", \
         sum501_1000pctHour[x]/metricDayHourCount[x],
         "'>1000%'", \
         sum1001_0000pctHour[x]/metricDayHourCount[x]
   }
}

