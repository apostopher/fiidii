loadGraph = new BGraph holder: "chartcontent", height: 500, type: "l"
loadGraph.setMessage "Loading..."

$.getJSON '/tools/fiidii/serverscripts/fiidii.php', (response) ->
  txt         =
    font         : '12px Helvetica, Arial', "font-weight": "bold"
    fill         : "#3C60A4"
  txt1        =
    font         : '10px Helvetica, Arial'
    fill         : "#666"
  months         =  ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

  loadGraph.setData response.curr, "bb_date", "usd"
  r = loadGraph.paper
  label = do r.set
  label_visible = false
  leave_timer = 0
  label.push (r.text 60, 12, "Rs.").attr txt
  label.push (r.text 60, 27, "date").attr txt1
  do label.hide
  frame = (r.popup 100, 100, label, "right").attr(fill: "#F9FAFC", stroke: "#DBDCDE", "stroke-width": 1, "fill-opacity": 1).hide()

  loadGraph.hover (rect, dot, data, date) ->
    rect.attr opacity: 0.04
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
    rect.attr opacity: 0
    dot.attr "r", 4
    leave_timer = setTimeout ->
      do frame.hide
      do label.hide
      label_visible = false
    , 1
          
  do loadGraph.draw
  