
function _gchartHeader () {
   print "<html>"
   print "<head>"
   print "   <script type=\"text/javascript\" src=\"https://www.gstatic.com/charts/loader.js\"></script>"
   print "   <script type=\"text/javascript\">"
   print "      google.charts.load('current', {'packages':['corechart']});"
}

function _gchartReturnLoadOnCallbacks (chart_count) {
   x=1
   while (x <= chart_count) {
      print "      google.charts.setOnLoadCallback(drawChart"x");"
      x+=1
   }
}

function _gchartBeginDrawChart (chart_number, column_list) {
   print "      function drawChart"chart_number"() {"
   print "         var data"chart_number" = google.visualization.arrayToDataTable(["
   print "            ["column_list"],"
}

function _gchartEndDrawChart (chart_number, chart_title) {
   print "         var options"chart_number" = {"
   print "            title: '"chart_title"',"
   print "            hAxis: {format: 'MMMdd HH:mm'},"
   if ( log_scale == 1 ) {
      print "            vAxis: {scaleType: 'log'},"
   }
   print "            curveType: 'function',"
   print "            legend: { position: 'bottom' }"
   print "         };"
   print "         var chart = new google.visualization.LineChart(document.getElementById('line_chart"chart_number"'));"
   print "         chart.draw(data"chart_number", options"chart_number");"
   print "      }"
}

function _gchartQuoteItemList (item_list) {
   sub("^","'",item_list)
   gsub(",","','",item_list)
   sub("$","'",item_list)
   return item_list
}

BEGIN {
   FS = ",";
   total_chart_count=0
   # Variables
   # log_scale=0
   column_list=_gchartQuoteItemList(column_list)

   column_count=split(column_list, foo, ",")
}

{
   total_metrics+=1
   if (!($1 in list_of_charts)) {
      list_of_charts[$1]
      total_number_of_charts+=1
   }
   metric_count[$1]+=1
   # Months are zero based in Javascript.
   js_month=$3-1
   if ( column_count == 2 ) {
      chart_data[$1","metric_count[$1]]="new Date("$2","js_month","$4","$5","$6","$7",0),"$8
   }
   else if ( column_count == 3 ) {
      chart_data[$1","metric_count[$1]]="new Date("$2","js_month","$4","$5","$6","$7",0),"$8","$9
   }
   else if ( column_count == 4 ) {
      chart_data[$1","metric_count[$1]]="new Date("$2","js_month","$4","$5","$6","$7",0),"$8","$9","$10
   }
   else if ( column_count == 5 ) {
      chart_data[$1","metric_count[$1]]="new Date("$2","js_month","$4","$5","$6","$7",0),"$8","$9","$10","$11
   }
}

END {
   _gchartHeader()
   _gchartReturnLoadOnCallbacks(total_number_of_charts)
   chart_number=0
   for (chart_title in list_of_charts) {
      chart_number+=1
      _gchartBeginDrawChart(chart_number, column_list)
      metric_number=1
      while (metric_number <= metric_count[chart_title]) {
         if ( metric_number < metric_count[chart_title]) {
            print "            ["chart_data[chart_title","metric_number]"],"
         }
         else {
            # Close things out, this is the last metric for the chart.
            print "            ["chart_data[chart_title","metric_number]"]"
            print "            ]);"
         }
         metric_number+=1
      }
      _gchartEndDrawChart(chart_number, chart_title)
   }
   print "   </script>"
   print "</head>"
   print "<body>"
   chart_number=0
   for (chart_title in list_of_charts) {
      chart_number+=1
      print "   <div id=\"line_chart"chart_number"\" style=\"width: 44%; height: 55%; display: inline-block\"></div>"
   }
   print "</body>"
   print "</html>"
}

      