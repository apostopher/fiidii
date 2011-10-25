window.loadGraph = new BGraph holder: "chartcontent", height: 500, type: "l"
loadGraph.setMessage "Loading..."

prepareData = (rawData, dateField) ->
  dateDiff = (a, b) ->
    aArray = a[dateField].split "-"
    bArray = b[dateField].split "-"
    aDate = new Date aArray[0], aArray[1] - 1, aArray[2]
    bDate = new Date bArray[0], bArray[1] - 1, bArray[2]
    aDate - bDate
  
  sortedData = rawData.sort dateDiff

toRound = (value) ->
  return (Math.round(value * 100) / 100).toFixed 2

$.getJSON '/tools/fiidii/serverscripts/fiidii.php', (response) ->
  txt         =
    font         : '12px Helvetica, Arial', "font-weight": "bold"
    fill         : "#3C60A4"
  txt1        =
    font         : '10px Helvetica, Arial'
    fill         : "#666"
  months         =  ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  
  window.response = response
  sortedCurr = prepareData response.c, "x"
  sortedD = prepareData response.d, "x"

  #loadGraph.setSecondaryData sortedD, "y"
  loadGraph.setData sortedCurr, "x", "u"

  #Load currency values
  latestRates = sortedCurr.slice(-1)[0]
  ($ "#usd").html latestRates.u
  ($ "#gbp").html latestRates.g
  ($ "#euro").html latestRates.e
  ($ "#yen").html latestRates.y

  ($ "#fiibuy").html response.fb
  ($ "#fiisell").html response.fs
  fiinet = toRound response.fb - response.fs
  ($ "#fiinet").html fiinet
  if fiinet < 0 then ($ "#fiinet").addClass "red"

  ($ "#diibuy").html response.db
  ($ "#diisell").html response.ds
  diinet = toRound response.db - response.ds
  ($ "#diinet").html diinet
  if diinet < 0 then ($ "#diinet").addClass "red"

  fiidiibuy = toRound 1 * response.fb + 1 * response.db
  fiidiisell = toRound 1 * response.fs + 1 * response.ds
  ($ "#fiidiibuy").html fiidiibuy
  ($ "#fiidiisell").html fiidiisell
  fiidiinet = toRound fiidiibuy - fiidiisell
  ($ "#fiidiinet").html fiidiinet
  if fiidiinet < 0 then ($ "#fiidiinet").addClass "red"
  
  ($ "#tdspan").html response.t
  
  r = loadGraph.paper
  label = do r.set
  label_visible = false
  leave_timer = 0
  label.push (r.text 60, 12, "Rs.").attr txt
  label.push (r.text 60, 27, "date").attr txt1
  do label.hide
  frame = (r.popup 100, 100, label, "right").attr(fill: "#F9FAFC", stroke: "#DBDCDE", "stroke-width": 1, "fill-opacity": 1).hide()
  loadGraph.setHoverLabels null, '#{y} Rupees = 1 USD'
  #loadGraph.setSecondaryHoverLabels null, '#{y} thousand crores'
  loadGraph.draw false, -25
