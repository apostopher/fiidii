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
  ###
  loadGraph.hover (rect, dot, data, date) ->
    clearTimeout leave_timer
    label[0].attr text: data + " " + "thousand crore Rs."
    label[1].attr text: do date.getDate + "-" + months[do date.getMonth]
    side = "right"
    side = "left"  if (dot.attr "cx") + frame.getBBox().width > r.width
    ppp = r.popup (dot.attr "cx"), (dot.attr "cy"), label, side, 1
    lx = label[0].transform()[0][1] + ppp.dx
    ly = label[0].transform()[0][2] + ppp.dy
    anim = Raphael.animation {path: ppp.path, transform: ["t", ppp.dx, ppp.dy]}, 200 * label_visible
    frame.show().stop().animate anim
    label[0].show().stop().animateWith frame, anim, {transform: ["t", lx, ly]}, 200 * label_visible
    label[1].show().stop().animateWith frame, anim, {transform: ["t", lx, ly]}, 200 * label_visible
    dot.attr "r", 6
    label_visible = true
    do frame.toFront
    do label.toFront
    
  ,(rect, dot, data, date) ->
    dot.attr "r", 4
    leave_timer = setTimeout ->
      do frame.hide
      do label[0].hide
      do label[1].hide
      label_visible = false
    , 1
   ###       
  loadGraph.draw -25
