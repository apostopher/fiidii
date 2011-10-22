global = exports ? this

class global.BGraph

  # Private vars.
  leftgutter     =  30
  topgutter      =  20
  bottomgutter   =  50
  months         =  ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  txtY           =
      font       :  '11px Helvetica, Arial'
      fill       :  "#666"
      "text-anchor": "start"
  lineAttr    =
      stroke            : "#3C60A4"
      "stroke-width"    : 3
      "stroke-linejoin" : "round"
  dotAttr     =
      fill           : "#fff"
      stroke         : "#3C60A4"
      "stroke-width" : 2
  blanketAttr =
      stroke       : "none"
      fill         : "#fff"
      opacity      : 0
  txt         =
      font         : '11px Helvetica, Arial'
      fill         : "#666"
  
  txtLY       =
    font         : '12px Helvetica, Arial', "font-weight": "bold"
    fill         : "#3C60A4"

  txtLX       =
    font         : '10px Helvetica, Arial'
    fill         : "#666"

  bpAttr      =
    "stroke-opacity" : "0.000001"
    stroke           : "#FFF"
    "stroke-width"   : "24"

  constructor: (@options) ->

    if not options.width? then options.width = do ($ "#" + options.holder).width
    @paper = Raphael options.holder, options.width, options.height

    # These are the chart variables which depend on @paper
    @chartProps  =
      yLabels      :  null
      xLabels      :  null
      chartMsg     :  null
      blanket      :  null
      dots         :  null
      linepath     :  null
    
    @chartData     =
      yData        :  []
      xData        :  []

    # Events object
    @events        =  hover :
                        overFn : null
                        outFn  : null
    @popup         =  yFormat :  '#{y}', xFormat : '#{x}'
    #get data from options.
    if options.data
      loadData options.data, options.type, options.xname, options.yname
  
  # Private method: This method draws the graph grid.
  drawGrid = (r, x, y, w, h, wv, hv) ->
    grid = do r.set
    gridPath = []
    axisPath = []
    rowHeight = h / hv
    columnWidth = w / wv

    xRound = Math.round x

    gridPath = gridPath.concat ["M", xRound + .5, Math.round(y + i * rowHeight) + .5, "H", Math.round(x + w) + .5] for i in [0..hv-1]

    #gridPath = gridPath.concat ["M", Math.round(x + i * columnWidth) + .5, Math.round(y) + .5, "V", Math.round(y + h) + .5] for i in [1..wv]
    
    axisPath = axisPath.concat ["M", xRound + .5, Math.round(y + hv * rowHeight) + .5, "H", Math.round(x + w) + .5]
    axisPath = axisPath.concat ["M", Math.round(x) + .5, Math.round(y) + .5, "V", Math.round(y + h) + .5]
    
    hLines = r.path gridPath.join ","
    hLines.attr stroke: "#eee"

    axis = r.path axisPath.join ","
    axis.attr stroke: "#ccc"

    grid.push axis
    grid.push hLines
    grid

  # Private method: This method draws the Y-axis labels.
  drawYLabels = (r, x, y, h, hv, yRange) ->
    xRound = Math.round x
    rowHeight = h / hv
    yLabels = do r.set
    for i in [0..hv]
      yStep = (yRange.endPoint - (i * yRange.step)).toFixed 2
      yLabel = r.text 0, Math.round(y + i * rowHeight) + .5, yStep
      yWidth = yWidth || yLabel.getBBox().width
      txtY.x = xRound - yWidth - 5
      yLabel.attr(txtY).toBack()
      yLabels.push yLabel
    yLabels

  # Private method: This method calculates the min and max Y values and step size
  # for Y labels. This method must be called after every update in order to
  # calculate new high, low and step for chart.
  # May need refactoring in future.
  getYRange = (steps = 8, minOrig, maxOrig) ->
    dataYRange = maxOrig - minOrig
    tempStep = dataYRange / (steps - 1)
    if 0.1 < tempStep <= 1
      base = 0.1
    else if 1 < tempStep < 10
      base = 1
    else if  tempStep >= 10
      base = 10
    else
      return

    base = base / 2 while tempStep % base <= base / 2
    step = tempStep + base - tempStep % base
    stepRange = step * steps
    rangeGutter = stepRange - dataYRange - step / 2
    startPoint = minOrig - rangeGutter + base - (minOrig - rangeGutter) % base
    endPoint = startPoint + stepRange

    {startPoint, endPoint,  step}

  # Private method: Calculate anchors for smooth line graph.
  getAnchors = (p1x, p1y, p2x, p2y, p3x, p3y) ->
    if p2x is p3x and p2y is p3y
      return x1: p2x, y1: p2y, x2: p2x, y2: p2y

    l1 = (p2x - p1x) / 2
    l2 = (p3x - p2x) / 2
    a = Math.atan((p2x - p1x) / Math.abs(p2y - p1y))
    b = Math.atan((p3x - p2x) / Math.abs(p2y - p3y))
    a = if p1y < p2y then Math.PI - a else a
    b = if p3y < p2y then Math.PI - b else b
    alpha = Math.PI / 2 - ((a + b) % (Math.PI * 2)) / 2
    dx1 = l1 * Math.sin alpha + a
    dy1 = l1 * Math.cos alpha + a
    dx2 = l2 * Math.sin alpha + b
    dy2 = l2 * Math.cos alpha + b

    x1: p2x - dx1
    y1: p2y + dy1
    x2: p2x + dx2
    y2: p2y + dy2

  # Private method: This method is used by hover and redraw functions
  # This is created as per DRY. as two functions need same functionality
  attachHover = (rect, index, overFn, outFn, dots, blanket, activeXData, activeYData) ->
    rect.hover ->
      overFn.call @, rect, dots[index], activeYData[index], activeXData[index]
      do blanket.toFront
      true
    , ->
      outFn.call @, rect, dots[index], activeYData[index], activeXData[index]
      do blanket.toFront
      true
    true
  
  # Public method: default over function
  defaultHoverFns: () ->
    frameAttr = fill: "#F9FAFC", stroke: "#DBDCDE", "stroke-width": 1, "fill-opacity": 1
    label = do @paper.set
    label_visible = false
    leave_timer = 0
    r = @paper
    yLegend = @popup.yFormat
    xLegend = @popup.xFormat

    label.push (@paper.text 60, 12, "").attr txtLY
    label.push (@paper.text 60, 27, "").attr txtLX
    do label.hide
    frame = (@paper.popup 100, 100, label, "right").attr(frameAttr).hide()

    getLabelText = (formatStr, x, y) ->
      yLArray = formatStr.split '#{y}'
      yReplaced = yLArray.join y

      xLArray = yReplaced.split '#{x}'
      xReplaced = xLArray.join x

    overFn = (rect, dot, data, date) ->
      clearTimeout leave_timer
      dateStr = do date.getDate + "-" + months[do date.getMonth] + "-" + date.getFullYear()
      label[0].attr text: getLabelText yLegend, dateStr, data
      label[1].attr text: getLabelText xLegend, dateStr, data
      side = "right"
      side = "left"  if (dot.attr "cx") + frame.getBBox().width > r.width
      ppp = @paper.popup (dot.attr "cx"), (dot.attr "cy"), label, side, 1
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

    outFn = (rect, dot, data, date) ->
      dot.attr "r", 4
      leave_timer = setTimeout ->
        do frame.hide
        do label[0].hide
        do label[1].hide
        label_visible = false
      , 1

    {overFn, outFn}

  # Public method: set the chart data. This is useful when chart data is received
  # in AJAX request. The loading message can be displayed till the data is received.
  setData: (data, xname = "x", yname = "y") ->
    @options.data = data
    @options.xname = xname
    @options.yname = yname
    
    @chartData.yData = _.map data, (dataItem) -> +dataItem[yname] || 0
    if @options.type is "l"
      # Accept dates as string and create date objects from it.
      @chartData.xData = _.map data, (dataItem) ->
        dateArray = dataItem[xname].split "-"
        new Date dateArray[0], dateArray[1] - 1, dateArray[2]
    else
      @chartData.xData = _.map data, (dataItem) -> dataItem.x
    @

  # Public method: attach user-specific hover event handlers to blanket elements.
  # If this is called before draw, it just stores the event handlers
  # If this is called after draw, it will loop over blanket elements and update
  # hover event handlers
  hover: (overFn, outFn) ->
    # check whether event object has hover
    @events.hover = {overFn, outFn}
    if @chartProps.blanket.length isnt 0
      for rect, index in @chartProps.blanket
        attachHover.call @, rect, index, overFn, outFn
    @

  # Public method: set the labels for default popup
  setHoverLabels: (xL = '#{x}', yL = '#{y}') ->
    @popup.xFormat = xL
    @popup.yFormat = yL
    @
       
  toString: ->
    "Bgraph version 0.2."

  # Public method: Used to post a message on canvas. center aligned vertically
  # as well as horizontally. Useful to post a message while we are fetching the
  # chart data from some ajax call.
  # TODO: message style is not customizable
  setMessage: (message, style) ->
    txtMsg      =
      "font-size"  : 18
      "font-weight": 300
      fill         : "#999"
      opacity      : 0

    # chartMsg is a set of messages. Can hold multiple messages
    do @chartProps.chartMsg?.remove
    delete @chartProps.chartMsg
    @chartProps.chartMsg = do @paper.set
    msg = (@paper.text @options.width / 2, @options.height / 2, message).attr (style ? txtMsg)

    # add message to chartMsg
    @chartProps.chartMsg.push msg
    msg.animate {opacity: 1}, 200
    @

  # Public method: This method accepts X and Y values and draws chart.
  # Currently this supports only one chart.
  draw: (start = 0, end) ->
    #private variables
    p = []
    
    # clear the stage
    if @chartProps.yLabels?.length
      do @chartProps.yLabels.remove
      delete @chartProps.yLabels

    if @chartProps.xLabels?.length
      do @chartProps.xLabels.remove
      delete @chartProps.xLabels 
    @chartProps.xLabels = do @paper.set
      
    if @chartProps.chartMsg?
      do @chartProps.chartMsg.remove
      delete @chartProps.chartMsg

    if @chartProps.blanket?.length
      do @chartProps.blanket.remove
      delete @chartProps.blanket
    @chartProps.blanket = do @paper.set

    #set active data
    if end?
      activeYData = @chartData.yData.slice start, end
      activeXData = @chartData.xData.slice start, end
    else
      activeYData = @chartData.yData.slice start
      activeXData = @chartData.xData.slice start

    gridRange = activeYData.length
    if not gridRange
      @setMessage "Empty dataset..."
      return false

    # Get max and min of chart data
    max = Math.max activeYData...
    min = Math.min activeYData...
    
    yRange = getYRange 8, min, max
    if yRange?
      max = yRange.endPoint
      min = yRange.startPoint
    else
      return self

    # Draw the grid
    X = (@options.width - leftgutter) / gridRange
    Y = (@options.height - bottomgutter - topgutter) / (max - min)

    if not @chartProps.grid
      @chartProps.grid = drawGrid @paper, leftgutter + X * .5, topgutter + .5, @options.width - leftgutter - X, @options.height - topgutter - bottomgutter, gridRange - 1, 8

    if @chartProps.linepath?
      do @chartProps.linepath.remove
      delete @chartProps.linepath
    @chartProps.linepath = do @paper.path

    if @chartProps.dots?.length
      do @chartProps.dots.remove
      delete @chartProps.dots
    @chartProps.dots = do @paper.set

    # Create X-Axis labels from date array
    labels = _.map activeXData, (date) -> do date.getDate + "-" + months[do date.getMonth]

    #draw labels
    @chartProps.yLabels = drawYLabels @paper, leftgutter + X * .5, topgutter + .5, @options.height - topgutter - bottomgutter, 8, yRange
    
    #draw chart
    @chartProps.linepath.attr lineAttr

    #set event functions
    if not @events.hover.overFn
      {overFn, outFn} = do @defaultHoverFns
      @events.hover.overFn = overFn
      @events.hover.outFn = outFn
    
    for i in [0...gridRange]
      oldX = x
      oldY = y
      y = @options.height - bottomgutter - Y * (activeYData[i] - min)
      x = Math.round leftgutter + X * (i + .5)

      if i is 0
        p = ["M", x, y, "C", x, y]
        oldX2 = x
        oldY2 = y
        subPathLen = 0
      if i isnt 0 and i < gridRange
        Y0 = @options.height - bottomgutter - Y * (activeYData[i - 1] - min)
        X0 = Math.round leftgutter + X * (i - .5)
        if activeYData[i + 1]
          Y2 = @options.height - bottomgutter - Y * (activeYData[i + 1] - min)
          X2 = Math.round leftgutter + X * (i + 1.5)
        else
          Y2 = y
          X2 = x
        a = getAnchors X0, Y0, x, y, X2, Y2
        p = p.concat [a.x1, a.y1, x, y, a.x2, a.y2]
        
        subPathString = ["M", oldX, oldY, "C", oldX2, oldY2, a.x1, a.y1, x, y].join ","
        oldSubPathLen = subPathLen
        subPathLen = Raphael.getTotalLength subPathString
        pathString = p.join ","
        pathLen = Raphael.getTotalLength pathString
        rectPath = Raphael.getSubpath pathString, pathLen - subPathLen - oldSubPathLen / 2, pathLen - subPathLen / 2
        
        lineRect = @paper.path rectPath
        lineRect.attr bpAttr

        @chartProps.blanket.push lineRect
        blanketLength = @chartProps.blanket.length
      
        attachHover.call @, lineRect, blanketLength - 1, @events.hover.overFn, @events.hover.outFn, @chartProps.dots, @chartProps.blanket, activeXData, activeYData

        oldX2 = a.x2
        oldY2 = a.y2

      @chartProps.dots.push @paper.circle(x, y, 4).attr dotAttr
      @chartProps.xLabels.push (@paper.text x, @options.height - 25, labels[i]).attr(txt).toBack().rotate 90
      
    rectPath = Raphael.getSubpath pathString, pathLen - subPathLen / 2, pathLen
    lineRect = @paper.path rectPath
    lineRect.attr bpAttr

    @chartProps.blanket.push lineRect
    blanketLength = @chartProps.blanket.length
    attachHover.call @, lineRect, blanketLength - 1, @events.hover.overFn, @events.hover.outFn, @chartProps.dots, @chartProps.blanket, activeXData, activeYData

    @chartProps.linepath.attr path: p
    do @chartProps.blanket.toFront
    @