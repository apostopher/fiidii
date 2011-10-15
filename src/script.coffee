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
  loadGraph.setData sortedCurr, "x", "u"

  #Load currency values
  latestRates = sortedCurr.slice(-1)[0]
  ($ "#usd").html latestRates.u
  ($ "#gbp").html latestRates.g
  ($ "#euro").html latestRates.e
  ($ "#yen").html latestRates.y

  ($ "#fiibuy").html response.fb
  ($ "#fiisell").html response.fs
  fiinet = ((response.fb * 100 - response.fs * 100) / 100)
  ($ "#fiinet").html fiinet
  if fiinet < 0 then ($ "#fiinet").addClass "red"

  ($ "#diibuy").html response.db
  ($ "#diisell").html response.ds
  diinet = ((response.db * 100 - response.ds * 100) / 100)
  ($ "#diinet").html diinet
  if diinet < 0 then ($ "#diinet").addClass "red"

  fiidiibuy = (response.fb * 100 + response.db * 100) / 100
  fiidiisell = (response.fs * 100 + response.ds * 100) / 100
  ($ "#fiidiibuy").html fiidiibuy
  ($ "#fiidiisell").html fiidiisell
  fiidiinet = (((fiidiibuy * 100) - (fiidiisell * 100)) / 100)
  ($ "#fiidiinet").html fiidiinet
  if fiidiinet < 0 then ($ "#fiidiinet").addClass "red"
  
  r = loadGraph.paper
  label = do r.set
  label_visible = false
  leave_timer = 0
  label.push (r.text 60, 12, "Rs.").attr txt
  label.push (r.text 60, 27, "date").attr txt1
  do label.hide
  frame = (r.popup 100, 100, label, "right").attr(fill: "#F9FAFC", stroke: "#DBDCDE", "stroke-width": 1, "fill-opacity": 1).hide()
  loadGraph.setHoverLabels null, '#{y} Rupees = 1 USD'
  loadGraph.draw -25
