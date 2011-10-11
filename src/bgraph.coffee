global = exports ? this

class global.BGraph

  # Private vars.
  r              =  null
  yLabels        =  null
  xLabels        =  null
  dots           =  null
  chartMsg       =  null
  blanket        =  null
  linepath       =  null
  yData          =  []
  xData          =  []
  events         =  {}
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

  constructor: (@options) ->

    if not options.width? then options.width = do ($ "#" + options.holder).width
    @paper = r = Raphael options.holder, options.width, options.height

    # These are the private variables again which depend on r
    yLabels        =  do r.set
    xLabels        =  do r.set
    dots           =  do r.set
    chartMsg       =  do r.set
    blanket        =  do r.set
    linepath       =  do r.path

    #get data from options.
    if options.data
      loadData options.data, options.type, options.xname, options.yname
  
  # Private method: This method draws the graph grid.
  drawGrid = (x, y, w, h, wv, hv) ->
    gridPath = []
    axisPath = []
    rowHeight = h / hv
    columnWidth = w / wv

    xRound = Math.round x

    gridPath = gridPath.concat ["M", xRound + .5, Math.round(y + i * rowHeight) + .5, "H", Math.round(x + w) + .5] for i in [0..hv-1]

    #gridPath = gridPath.concat ["M", Math.round(x + i * columnWidth) + .5, Math.round(y) + .5, "V", Math.round(y + h) + .5] for i in [1..wv]
    
    axisPath = axisPath.concat ["M", xRound + .5, Math.round(y + hv * rowHeight) + .5, "H", Math.round(x + w) + .5]
    axisPath = axisPath.concat ["M", Math.round(x) + .5, Math.round(y) + .5, "V", Math.round(y + h) + .5]

    (r.path gridPath.join ",").attr stroke: "#eee"
    (r.path axisPath.join ",").attr stroke: "#ccc"
  
  # Private method: This method draws the Y-axis labels.
  drawLabels = (x, y, h, hv, yRange) ->
    xRound = Math.round x
    rowHeight = h / hv

    for i in [0..hv]
      yStep = (yRange.endPoint - (i * yRange.step)).toFixed 2
      yLabel = r.text xRound, Math.round(y + i * rowHeight) + .5, yStep
      yLabels.push yLabel
      yWidth = yWidth || yLabel.getBBox().width
      txtY.x || txtY.x = xRound - yWidth - 5
      yLabel.attr(txtY).toBack()
    true

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
  # this is taken as-is from http://raphaeljs.com/analytics.html
  getAnchors = (p1x, p1y, p2x, p2y, p3x, p3y) ->
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
  attachHover = (rect, index, overFn, outFn) ->
    rect.hover ->
      overFn.call @, rect, dots[index], yData[index], xData[index]
      do blanket.toFront
      true
    , ->
      outFn.call @, rect, dots[index], yData[index], xData[index]
      do blanket.toFront
      true
    true
  
  #Private method: load data
  loadData = (data, type = "l", xname = "x", yname = "y") ->
    yData = _.map data, (dataItem) -> +dataItem[yname] || 0

    if type is "l"
      # Accept dates as string and create date objects from it.
      xData = _.map data, (dataItem) ->
        dateArray = dataItem[xname].split "-"
        new Date dateArray[0], dateArray[1] - 1, dateArray[2]
    else
      xData = _.map data, (dataItem) -> dataItem.x

  # Public method: set the chart data. This is useful when chart data is received
  # in AJAX request. The loading message can be displayed till the data is received.
  setData: (data, xname, yname) ->
    @options.data = data
    if xname then @options.xname = xname
    if yname then @options.yname = yname

    loadData data, @options.type, @options.xname, @options.yname
    @

  # Public method: attach user-specific hover event handlers to blanket elements.
  # If this is called before draw, it just stores the event handlers
  # If this is called after draw, it will loop over blanket elements and update
  # hover event handlers
  hover: (overFn, outFn) ->
    # check whether event object has hover
    events.hover = {overFn, outFn}
    if blanket.length isnt 0
      for rect, index in blanket
        attachHover.call @, rect, index, overFn, outFn
    @
       
  toString: ->
    "You are using Bgraph version 0.2."

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
    do chartMsg.remove
    msg = (r.text @options.width / 2, @options.height / 2, message).attr (style ? txtMsg)

    # add message to chartMsg
    chartMsg.push msg
    msg.animate {opacity: 1}, 200
    @

  # Public method: This method accepts X and Y values and draws chart.
  # Currently this supports only one chart.
  draw: () ->
    #private variables
    p = []
    
    gridRange = yData.length
    if not gridRange
      @setMessage "Empty dataset..."
      return false

    # Get max and min of chart data
    max = Math.max yData...
    min = Math.min yData...
    
    yRange = getYRange 8, min, max
    if yRange?
      max = yRange.endPoint
      min = yRange.startPoint
    else
      return self
    
    # Remove message
    if chartMsg?
      do chartMsg.remove
      delete chartMsg
      chartMsg = do r.set

    # Draw the grid
    X = (@options.width - leftgutter) / gridRange
    Y = (@options.height - bottomgutter - topgutter) / (max - min)

    drawGrid leftgutter + X * .5, topgutter + .5, @options.width - leftgutter - X, @options.height - topgutter - bottomgutter, gridRange - 1, 8

    # Create X-Axis labels from date array
    labels = _.map xData, (date) -> do date.getDate + "-" + months[do date.getMonth]

    #draw labels
    drawLabels leftgutter + X * .5, topgutter + .5, @options.height - topgutter - bottomgutter, 8, yRange
    
    #draw chart
    linepath = do r.path
    linepath.attr lineAttr
    for i in [0...gridRange]
      y = @options.height - bottomgutter - Y * (yData[i] - min)
      x = Math.round leftgutter + X * (i + .5)

      p = ["M", x, y, "C", x, y] if i is 0
      if i isnt 0 and i < gridRange - 1
        Y0 = @options.height - bottomgutter - Y * (yData[i - 1] - min)
        X0 = Math.round leftgutter + X * (i - .5)
        Y2 = @options.height - bottomgutter - Y * (yData[i + 1] - min)
        X2 = Math.round leftgutter + X * (i + 1.5)
        a = getAnchors X0, Y0, x, y, X2, Y2
        p = p.concat [a.x1, a.y1, x, y, a.x2, a.y2]
      dots.push r.circle(x, y, 4).attr dotAttr
      xLabels.push (r.text x, @options.height - 25, labels[i]).attr(txt).toBack().rotate 90
      blanket.push (r.rect leftgutter + X * i, 0, X, @options.height - bottomgutter).attr blanketAttr
      rect = blanket[blanket.length - 1]
      if events.hover?.overFn? and events.hover?.outFn?
        attachHover.call @, rect, blanket.length - 1, events.hover.overFn, events.hover.outFn

    p = p.concat [x, y, x, y]
    linepath.attr path: p
    do blanket.toFront
    @