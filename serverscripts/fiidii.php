<?php
//Include the database.
require_once("dba.php");
$dloadrequest = $_GET['req'];
if($dloadrequest == "dl"){
  $csvstr = "";
  $selectclause = "";
  $limitclause = "";
  
  $tperiod = $_GET['tperiod'];
  
  if($tperiod == "1m"){
    $limitclause = "LIMIT 25";
  }else if($tperiod == "3m"){
    $limitclause = "LIMIT 75";
  }else if($tperiod == "6m"){
    $limitclause = "LIMIT 150";
  }else if($tperiod == "12m"){
    $limitclause = "LIMIT 300";
  }else if($tperiod == "all"){
    $limitclause = "";
  }else{
    $limitclause = "LIMIT 25"; /* default to 1 month */
  }
  
  $ctype = $_GET['ctype'];
  
  if($ctype == "both"){
    $selectclause = "fii,dii";
  }else if($ctype == "fii"){
    $selectclause = "fii";
  }else if($ctype == "dii"){
    $selectclause = "dii";
  }else{
    $selectclause = "fii,dii"; /* Default is both*/
  }
  $dload_query = "SELECT fiidii_date,".$selectclause." FROM fiidii ORDER BY fiidii_date DESC ".$limitclause;
  $dlresult = mysql_query($dload_query);
  if($dlresult){
    /* write headers */
    $csvstr = "Cumulative institutional investment in India\n";
    $csvstr = $csvstr."In Rs. crore\n";
    $csvstr = $csvstr."date,".$selectclause."\n";
    while($dlrow = mysql_fetch_array($dlresult)){
      if($selectclause == "fii"){
        $csvstr = $csvstr.$dlrow['fiidii_date'].",".$dlrow['fii']."\n";
      }else if($selectclause == "dii"){
        $csvstr = $csvstr.$dlrow['fiidii_date'].",".$dlrow['dii']."\n";
      }else{
        $csvstr = $csvstr.$dlrow['fiidii_date'].",".$dlrow['fii'].",".$dlrow['dii']."\n";
      }
    }
    $csvstr = $csvstr."=HYPERLINK(\"http://blackbull.in/tools/fiidii/index.php\")\n";
  }else{
    $csvstr = "Sorry. Some error occured. :(";
  }
  header('Content-type: text/csv');
  header("Content-Disposition: attachment;filename=Blackbull_chartdata.csv");
  if(strstr($_SERVER["HTTP_USER_AGENT"],"MSIE")==false) {
    header("Cache-Control: no-cache");
    header("Pragma: no-cache");
  }
  echo $csvstr;
  
  // open log file
  $filename = "fiidii_analytics.csv";
  $fd = fopen($filename, "a");
  // write string
  fwrite($fd, date("d/m/y : H:i:s", time()).",".$limitclause.",".$ctype."\n");
  // close file
  fclose($fd);

  mysql_close($con);
  return true;
}

$query = "SELECT fii,dii,fiidii_date FROM fiidii ORDER BY fiidii_date DESC LIMIT 260";
$result = mysql_query($query);
if($result){
	$i = 0;
	$data = array();
	while($row = mysql_fetch_array($result)){
		$fii = round($row['fii']/1000, 2);
		$dii = round($row['dii']/1000, 2);
		$total = round(($row['fii'] + $row['dii'])/1000, 2);
		$date = date("d-M", strtotime($row['fiidii_date']));
		array_push($data, array("x" => $row['fiidii_date'], "y" => $total, "f" => $fii, "d" => $dii));
		$i++;
	}
	$daily_move = "SELECT fiidii_date, fiibuy, fiisell ,diibuy ,diisell FROM fiidii ORDER BY fiidii_date DESC LIMIT 1";
	$dailyresult = mysql_query($daily_move);
	$dailyrow = mysql_fetch_array($dailyresult);
	
	$curr_data = "SELECT usd, gbp, euro, yen, bb_date FROM bb_currency ORDER BY bb_date DESC LIMIT 260";
	$currresult = mysql_query($curr_data);
	$i = 0;
	$curr = array();
	while($currrow = mysql_fetch_array($currresult)){
	  array_push($curr, array("x" => $currrow['bb_date'], "u" => $currrow['usd'], "g" => $currrow['gbp'], "e" => $currrow['euro'], "y" => $currrow['yen']));
	  $i++;
	}
	$indexQuery = "SELECT TIMESTAMP, CLOSE FROM cmbhav WHERE SYMBOL = \"NIFTY\" ORDER BY TIMESTAMP DESC LIMIT 260";
	$indexResult = mysql_query($indexQuery);
	$i = 0;
	$indexarr = array();
	while($indexrow = mysql_fetch_array($indexResult)){
	  array_push($indexarr, array("x" => $indexrow['TIMESTAMP'], "y" => $indexrow['CLOSE']));
	}
	
	$response = array("d" => $data, "c" => $curr, "i" => $indexarr, "fb" => $dailyrow['fiibuy'], "fs" => $dailyrow['fiisell'], "db" => $dailyrow['diibuy'], "ds" => $dailyrow['diisell'], "t" => date("j F Y", strtotime($dailyrow['fiidii_date'])));
	header('Content-type: application/json');
	if(strstr($_SERVER["HTTP_USER_AGENT"],"MSIE")==false) {
  		header("Cache-Control: no-cache");
  		header("Pragma: no-cache");
 	}
	echo json_encode($response);
	mysql_close($con);
}else{
	$response = array("total" => 0);
	header('Content-type: application/json');
	if(strstr($_SERVER["HTTP_USER_AGENT"],"MSIE")==false) {
  		header("Cache-Control: no-cache");
  		header("Pragma: no-cache");
 	}
	echo json_encode($response);
	mysql_close($con);
}
?>