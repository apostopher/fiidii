global = exports ? this

class global.BGraph

  # Private vars.
  leftgutter     =  30
  topgutter      =  20
  bottomgutter   =  50
  rightgutter    =  30
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

  pBlanketAttr =
      stroke       : "none"
      fill         : "#fff"
      opacity      : 0
  txt         =
      font         : '11px Helvetica, Arial'
      fill         : "#666"
  
  txtLY       =
    font         : '12px Helvetica, Arial'
    "font-weight": "bold"
    fill         : "#3C60A4"

  txtLX       =
    font         : '10px Helvetica, Arial'
    fill         : "#666"

  bpAttr      =
    "stroke-opacity" : "0.000001"
    stroke           : "#fff"
    "stroke-width"   : "30"

  constructor: (@options) ->

    holderwidth = do ($ "#" + options.holder).width
    if not options.width? then options.width = holderwidth
    @paper = Raphael options.holder, "100%", options.height

    # Calculate fit screen start
    availablewidth = holderwidth - leftgutter - rightgutter
    # 35px is the preferred distance between two points
    fitwidthsize = Math.floor availablewidth / 35
    # These are the chart variables which depend on @paper
    @chartData     =
      primaryYData :  []
      xData        :  []
      cache        :  {}
      fitwidth     :  fitwidthsize

    @popup  =  yFormat :  '#{y}', xFormat : '#{x}'

    # Events object
    @events        =  hover :
                        overFn : null
                        outFn  : null

    initializeStage @
  
  #Private method: This method initializes data
  initializeStage = (thisArg) ->
    thisArg.chartProps  =
      primaryYLabels      :  null
      xLabels             :  do thisArg.paper.set
      chartMsg            :  null
      pBlanket            :  do thisArg.paper.set
      pDots               :  do thisArg.paper.set
      primaryPath         :  do thisArg.paper.path

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
    do grid.toBack
    grid

  # Private method: This method draws the Y-axis labels.
  drawYLabels = (r, x, y, h, hv, yRange, w) ->
    xRound = Math.round x
    rowHeight = h / hv
    YLabels = do r.set
    for i in [0..hv]
      yStep = (yRange.endPoint - (i * yRange.step)).toFixed 2
      yLabel = r.text 0, Math.round(y + i * rowHeight) + .5, yStep
      if not w
        yWidth = yLabel.getBBox().width
        txtY.x = xRound - yWidth - 5
      else
        txtY.x = xRound + w + 5

      do yLabel.attr(txtY).toBack
      YLabels.push yLabel
    YLabels

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

    base = base / 2 while tempStep % base and tempStep % base <= base / 2
    step = tempStep + base - tempStep % base
    stepRange = step * steps
    rangeGutter = stepRange - dataYRange - step / 2
    startPoint = minOrig - rangeGutter + base - (minOrig - rangeGutter) % base
    endPoint = startPoint + stepRange

    {startPoint, endPoint,  step}

  # Private method: Calculate anchors for smooth line graph.
  getAnchors = (p1x, p1y, p2x, p2y, p3x, p3y) ->
    if p2x is p3x and p2y is p3y
      return x1: p2x, y1: p2y, x2: undefined, y2: undefined

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
  attachHover = (rect, index, overFn, outFn, pDots, pBlanket, activeXData, activePrimaryYData) ->
    rect.hover ->
      overFn.call @, rect, pDots[index], activePrimaryYData[index], activeXData[index]
      do pBlanket.toFront
      true
    , ->
      outFn.call @, rect, pDots[index], activePrimaryYData[index], activeXData[index]
      do pBlanket.toFront
      true
    true
  
  # Private method: This method adjusts the data to fit the screen
  adjustData = (yData, xData, step, maxNewData) ->
    newYData = []
    newXData = []
    sliceindex = 0 - step * maxNewData
    lastindex = yData.length - 1
    for y, index in yData
      if (lastindex - index) % step is 0
        newYData.push y
        newXData.push xData[index]

    [(newYData.slice sliceindex), newXData.slice sliceindex]

  # Public method: default over function
  defaultHoverFns: () ->
    label = do @paper.set
    label_visible = false
    leave_timer = 0
    r = @paper
    frameAttr = fill: "#F9FAFC", stroke: "#DBDCDE", "stroke-width": 1, "fill-opacity": 1
    yLegend = @popup.yFormat
    xLegend = @popup.xFormat
    textX = txtLX
    textY = txtLY

    label.push (@paper.text 60, 12, "").attr textY
    label.push (@paper.text 60, 27, "").attr textX
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
      console.log r.width
      side = "left"  if (dot.attr "cx") + frame.getBBox().width > r.canvas.width.baseVal.value
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
  setData: (data, xname = "x", yname = "y", dataname = "fiidii") ->
    if @chartData.cache[dataname]
      @chartData.primaryYData = @chartData.cache[dataname].y
      @chartData.xData = @chartData.cache[dataname].x
    else
      @chartData.primaryYData = map data, (dataItem) -> +dataItem[yname] || 0
      if @options.type is "l"
        # Accept dates as string and create date objects from it.
        @chartData.xData = map data, (dataItem) ->
          dateArray = dataItem[xname].split "-"
          new Date dateArray[0], dateArray[1] - 1, dateArray[2]

      else
        @chartData.xData = map data, (dataItem) -> dataItem.x

      @chartData.cache[dataname] = x: @chartData.xData, y: @chartData.primaryYData
      setTimeout =>
        delete @chartData.cache[dataname]
      , 3000
    # Attach the resize event handler
    #($ window).resize -> @draw false
    @

  # Public method: attach user-specific hover event handlers to pBlanket elements.
  # If this is called before draw, it just stores the event handlers
  # If this is called after draw, it will loop over pBlanket elements and update
  # hover event handlers
  hover: (overFn, outFn) ->
    # check whether event object has hover
    @events.hover = {overFn, outFn}
    if @chartProps.pBlanket.length isnt 0
      for rect, index in @chartProps.pBlanket
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
    do @paper.clear
    @chartProps.chartMsg = do @paper.set
    msg = (@paper.text @options.width / 2, @options.height / 2, message).attr (style ? txtMsg)

    # add message to chartMsg
    @chartProps.chartMsg.push msg
    msg.animate {opacity: 1}, 200
    @

  # Public method: This method accepts X and Y values and draws chart.
  # Currently this supports only one chart.
  draw: (primaryOnly, start, end) ->
    #private variables
    p = []
    
    # clear the stage
    do @paper.clear
    initializeStage @

    #set active data
    fitwidth = @chartData.fitwidth
    if not start?
      #start is not specified.
      # calculate start based on screen width
      start = 0 - fitwidth

    if end?
      activePrimaryYData = @chartData.primaryYData.slice start, end
      activeXData = @chartData.xData.slice start, end
    else
      activePrimaryYData = @chartData.primaryYData.slice start
      activeXData = @chartData.xData.slice start

    gridRange = activePrimaryYData.length
    if not gridRange
      @setMessage "Empty dataset..."
      return @

    if gridRange > fitwidth
      # We will have to drop some data to fit screen
      step = Math.floor gridRange / fitwidth
      [activePrimaryYData, activeXData] = adjustData activePrimaryYData, activeXData, step, fitwidth
      gridRange = activePrimaryYData.length
    else
      step = 1

    # Get max and min of chart data
    max = Math.max activePrimaryYData...
    min = Math.min activePrimaryYData...
    
    yRange = getYRange 8, min, max
    if yRange?
      max = yRange.endPoint
      min = yRange.startPoint
    else
      return self

    # Draw the grid
    X = (@options.width - leftgutter - rightgutter) / gridRange
    Y = (@options.height - bottomgutter - topgutter) / (max - min)

    if not @chartProps.grid
      @chartProps.grid = drawGrid @paper, leftgutter + X * .5, topgutter + .5, @options.width - leftgutter - rightgutter - X, @options.height - topgutter - bottomgutter, gridRange - 1, 8

    # Create X-Axis labels from date array
    labels = map activeXData, (date) -> do date.getDate + "-" + months[do date.getMonth]

    #draw labels
    @chartProps.primaryYLabels = drawYLabels @paper, leftgutter + X * .5, topgutter + .5, @options.height - topgutter - bottomgutter, 8, yRange
    
    #draw chart
    @chartProps.primaryPath.attr lineAttr

    #set event functions
    {overFn, outFn} = do @defaultHoverFns
    @events.hover.overFn = overFn
    @events.hover.outFn = outFn
    
    for i in [0...gridRange]
      oldX = x
      oldY = y
      y = @options.height - bottomgutter - Y * (activePrimaryYData[i] - min)
      x = Math.round leftgutter + X * (i + .5)

      if i is 0
        p = ["M", x, y, "C", x, y]
        oldX2 = x
        oldY2 = y
        subPathLen = 0
        pathLen = 0
        subPathString = ""
      if i isnt 0 and i < gridRange
        Y0 = @options.height - bottomgutter - Y * (activePrimaryYData[i - 1] - min)
        X0 = Math.round leftgutter + X * (i - .5)
        if activePrimaryYData[i + 1]
          Y2 = @options.height - bottomgutter - Y * (activePrimaryYData[i + 1] - min)
          X2 = Math.round leftgutter + X * (i + 1.5)
        else
          Y2 = y
          X2 = x
        a = getAnchors X0, Y0, x, y, X2, Y2
        if a.x2 and a.y2
          p = p.concat [a.x1, a.y1, x, y, a.x2, a.y2]
        else
          p = p.concat [a.x1, a.y1, x, y]

        oldSubPathString = subPathString
        subPathString = ["M", oldX, oldY, "C", oldX2, oldY2, a.x1, a.y1, x, y].join ","
        oldSubPathLen = subPathLen
        subPathLen = Raphael.getTotalLength subPathString
        pathString = oldSubPathString + subPathString
        pathLen = oldSubPathLen + subPathLen
        rectPath = Raphael.getSubpath pathString, pathLen - subPathLen - oldSubPathLen / 2, pathLen - subPathLen / 2
        
        lineRect = @paper.path rectPath
        lineRect.attr bpAttr

        @chartProps.pBlanket.push lineRect
        pBlanketLength = @chartProps.pBlanket.length
      
        attachHover.call @, lineRect, pBlanketLength - 1, @events.hover.overFn, @events.hover.outFn, @chartProps.pDots, @chartProps.pBlanket, activeXData, activePrimaryYData

        oldX2 = a.x2
        oldY2 = a.y2

      @chartProps.pDots.push @paper.circle(x, y, 4).attr dotAttr
      @chartProps.xLabels.push (@paper.text x, @options.height - 25, labels[i]).attr(txt).toBack().rotate 90
      
    rectPath = Raphael.getSubpath pathString, pathLen - subPathLen / 2, pathLen
    lineRect = @paper.path rectPath
    lineRect.attr bpAttr

    @chartProps.pBlanket.push lineRect
    pBlanketLength = @chartProps.pBlanket.length
    attachHover.call @, lineRect, pBlanketLength - 1, @events.hover.overFn, @events.hover.outFn, @chartProps.pDots, @chartProps.pBlanket, activeXData, activePrimaryYData

    @chartProps.primaryPath.attr path: p
    do @chartProps.pBlanket.toFront
    @