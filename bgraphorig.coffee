global = exports ? this
global.bgraph = (options) ->
  # Private variables
  chartTypes  =     ["c", "l"]
  data        =     []
  dataL       =     []
  xlabels     =     []
  maxArray    =     []
  minArray    =     []
  dates       =     []
  range       =     0
  type        =     "l"
  xtext       =     ""
  ytext       =     ""
  columnWidth =     0
  dataRange   =     0
  currPos     =     0
  X           =     0
  Y           =     0
  prefWidth   =     36
  validColor  =     /^#{1}(([a-fA-F0-9]){3}){1,2}$/
  color       =     "#000"
  txt         =
      font         : '11px Helvetica, Arial'
      fill         : "#666"
  txtY        =
      font         : '11px Helvetica, Arial'
      fill         : "#666"
      "text-anchor": "start"
  dotAttr     =
      fill           : "#fff"
      stroke         : color
      "stroke-width" : 2
  blanketAttr =
      stroke       : "none"
      fill         : "#fff"
      opacity      : 0
  lineAttr    =
      stroke            : color
      "stroke-width"    : 3
      "stroke-linejoin" : "round"
  upAttr      =
      stroke            : "#000"
      fill              : "0-#ddd-#f9f9f9:50-#ddd"
      "stroke-linejoin" : "round"
  downAttr    =
      stroke            : "#000"
      fill              : "0-#222-#555:50-#222"
      "stroke-linejoin" : "round"
  hlAttr      =
      stroke            : "#000"
      "stroke-width"    : 1
      "stroke-linejoin" : "round"
  events      =     {}

  # private variables assignment
  {width, height, holder, leftgutter, topgutter, bottomgutter, gridColor} = options

  ### the following validation will work only when the value is a positive number.
    +undefined = NaN, +"hello" = NaN
    also NaN >= 0 is false and NaN < 0 is false too :)
    probably NaN is in 4th dimention...
  ###
  if not (+leftgutter >= 0) then leftgutter = 30
  if not (+topgutter >= 0) then topgutter = 20
  if not (+bottomgutter >= 0) then bottomgutter = 50
  if not validColor.test gridColor then gridColor = "#DFDFDF"

  if not width? then width = do ($ "#" + holder).width
  ($ "#"+holder).html ""

  # r is a public object. This is because users may want to draw custom shapes
  # on canvas. This object may be augmented in future to provide more information
  # and/or utility functions.
  r = Raphael holder, width, height

  # These are the private variables again which depend on r
  candelabra     =  do r.set
  yLabels        =  do r.set
  activeXLabels  =  do r.set
  dots           =  do r.set
  chartMsg       =  do r.set
  blanket        =  do r.set
  linepath       =  do r.path

  # Public method: Resize canvas after browser resize. This does not resize
  # canvas elements though.
  reSize = ->
    newWidth = do ($ "#" + holder).width
    newHeight = do ($ "#" + holder).height
    r.setSize newWidth, newHeight
    true

  # Public method: Prints the version number
  toString = ->
    "You are using Bgraph version 0.2."

  # Public method: Used to post a message on canvas. center aligned vertically
  # as well as horizontally. Useful to post a message while we are fetching the
  # chart data from some ajax call.
  # TODO: message style is not customizable
  setMessage = (message) ->
    txtErr      =
      font         : '24px Helvetica, Arial'
      fill         : "#999"
      opacity      : 0

    # chartMsg is a set of messages. Can hold multiple messages
    do chartMsg.remove
    msg = (r.text width / 2, height / 2, message).attr txtErr

    # add message to chartMsg
    chartMsg.push msg
    msg.animate {opacity: 1}, 200
    @

  # Private method: This method is used by hover and redraw functions
  # This is created as per DRY. as two functions need same functionality
  attachHover = (rect, index, overFn, outFn) ->
    rect.hover ->
      if type is "c"
        overFn.call @, rect, candelabra[index], data[currPos + index], dates[currPos + index]
      else if type is "l"
        overFn.call @, rect, dots[index], data[currPos + index], dates[currPos + index]
      do blanket.toFront
      true
    , ->
      if type is "c"
        outFn.call @, rect, candelabra[index], data[currPos + index], dates[currPos + index]
      else if type is "l"
        outFn.call @, rect, dots[index], data[currPos + index], dates[currPos + index]
      do blanket.toFront
      true
    true

  # Public method: attach user-specific hover event handlers to blanket elements.
  # If this is called before draw, it just stores the event handlers
  # If this is called after draw, it will loop over blanket elements and update
  # hover event handlers
  hover = (overFn, outFn) ->
    # check whether event object has hover
    events.hover = {overFn, outFn}
    if blanket.length isnt 0
      for rect, index in blanket
        attachHover.call @, rect, index, overFn, outFn
    @

  # Private method: This method draws the graph grid.
  # TODO: The grid style is not customizable
  drawGrid = (x, y, w, h, wv, hv) ->
    gridPath = []
    rowHeight = h / hv
    columnWidth = w / wv

    xRound = Math.round x

    gridPath = gridPath.concat ["M", xRound + .5, Math.round(y + i * rowHeight) + .5, "H", Math.round(x + w) + .5] for i in [0..hv]
    gridPath = gridPath.concat ["M", Math.round(x + i * columnWidth) + .5, Math.round(y) + .5, "V", Math.round(y + h) + .5] for i in [0..wv]

    (r.path gridPath.join ",").attr stroke: gridColor

  # Private method: This method draws the Y-axis labels.
  drawLabels = (x, y, h, hv, yValues) ->
    xRound = Math.round x
    rowHeight = h / hv

    for i in [0..hv]
      yStep = (yValues.endPoint - (i * yValues.step)).toFixed 2
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

  # Private method: This method draws one candlestick.
  # TODO: The candle style is not customizable
  drawCandlestick =  (dataItem, Y, x, y, color = "#000") ->
    o = +dataItem.o || 0
    h = +dataItem.h || 0
    l = +dataItem.l || 0
    c = +dataItem.c || 0
    if c > o then candleType = 1 else candleType = 0

    candleWidth = Math.round columnWidth / 2 - 4
    candleHeight = Math.round Y * (Math.abs c - o)
    if candleHeight is 0 then candleHeight = 1
    candle = r.set()

    stickPath = []
    stickPath = ["M", (Math.round x) + .5, (Math.round y) + .5, "V", Math.round y + (h - l) * Y]
    candle.push (r.path stickPath.join ",").attr hlAttr
    candleX = Math.round x - candleWidth / 2
    if candleType is 1
      candleY = Math.round y + (h-c) * Y
      candle.push (r.rect candleX + .5, candleY + .5, candleWidth, candleHeight).attr upAttr
    else
      candleY = Math.round y + (h-o) * Y
      candle.push (r.rect candleX + .5, candleY + .5, candleWidth, candleHeight).attr downAttr

    candleMid: Math.round candleY + candleHeight / 2
    candle: candle

  # Private method: This method redraws chart with new data points
  # This is NOT a well thought implementation. Needs refactoring
  # design change in future to support updating multiple charts on canvas
  # currently it can update only one chart.
  redraw = ->
    p              =     []

    if typeof data[0] is "object"
      if type is "c"
        max = Math.max maxArray[currPos...currPos + range]...
        min = Math.min minArray[currPos...currPos + range]...
      else
        max = Math.max dataL[currPos...currPos + range]...
        min = Math.min dataL[currPos...currPos + range]...
    else if typeof data[0] is "number"
      # line chart uses dataL as a source. not data.
      dataL = data
      if currPos is 0
        max = Math.max dataL...
        min = Math.min dataL...
      else
        max = Math.max dataL[currPos...currPos + range]...
        min = Math.min dataL[currPos...currPos + range]...

    yRange = getYRange 8, min, max
    if yRange?
      max = yRange.endPoint
      min = yRange.startPoint
    else
      return self

    Y = (height - bottomgutter - topgutter) / (max - min)
    # Before redraw, clear previous drawing
    if yLabels?
      do yLabels.remove
      delete yLabels
      yLabels = do r.set
    if activeXLabels?
      do activeXLabels.remove
      delete activeXLabels
      activeXLabels = do r.set
    if chartMsg?
      do chartMsg.remove
      delete chartMsg
      chartMsg = do r.set
    if blanket?
      do blanket.remove
      delete blanket
      blanket = do r.set
    if type is "c"
      do candelabra.remove
      delete candelabra
      candelabra = do r.set
    if type is "l"
      do linepath.remove
      do dots.remove
      delete linepath
      delete blanket
      linepath = do r.path
      dots = do r.set
    drawLabels leftgutter + X * .5, topgutter + .5, height - topgutter - bottomgutter, 8, yRange

    if type is "l"
      linepath.attr lineAttr
      for i in [currPos...currPos + range]
        y = height - bottomgutter - Y * (dataL[i] - min)
        x = Math.round leftgutter + X * (i - currPos + .5)

        p = ["M", x, y, "C", x, y] if i is currPos
        if i isnt currPos and i < currPos + range - 1
          Y0 = height - bottomgutter - Y * (dataL[i - 1] - min)
          X0 = Math.round leftgutter + X * (i - currPos - .5)
          Y2 = height - bottomgutter - Y * (dataL[i + 1] - min)
          X2 = Math.round leftgutter + X * (i - currPos + 1.5)
          a = getAnchors X0, Y0, x, y, X2, Y2
          p = p.concat [a.x1, a.y1, x, y, a.x2, a.y2]
        dots.push r.circle(x, y, 4).attr dotAttr
        activeXLabels.push (r.text x, height - 25, xlabels[i]).attr(txt).toBack().rotate 90
        blanket.push (r.rect leftgutter + X * (i - currPos), 0, X, height - bottomgutter).attr blanketAttr
        rect = blanket[blanket.length - 1]
        if events.hover?.overFn? and events.hover?.outFn?
          attachHover.call @, rect, blanket.length - 1, events.hover.overFn, events.hover.outFn

      p = p.concat [x, y, x, y]
      linepath.attr path: p
      do blanket.toFront
    else
      for i in [currPos + 1...currPos + range + 1]
        y = height - bottomgutter - Y * (data[i - 1].h - min)
        x = Math.round leftgutter + X * (i - currPos + .5)
        activeXLabels.push (r.text x, height - 25, xlabels[i - 1]).attr(txt).toBack().rotate 90
        candlestick = drawCandlestick data[i - 1], Y, x, y, color
        candelabra.push candlestick.candle
        blanket.push (r.rect leftgutter + X * (i - currPos), 0, X, height).attr blanketAttr
        rect = blanket[blanket.length - 1]
        if events.hover?.overFn? and events.hover?.outFn?
          attachHover.call @, rect, blanket.length - 1, events.hover.overFn, events.hover.outFn

      do blanket.toFront
    @

  # Public method: This method accepts X and Y values and draws chart.
  # Currently this supports only one chart.
  draw = (options) ->
    {color, data, xtext, ytext, type} = options
    dataRange = data.length
    if dataRange is 0
      setMessage "Symbol not found..."
      return false

    rawDates = options.dates
    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    if (_.indexOf chartTypes, type) is -1 then type = "l"

    if typeof data[0] is "object"
      if type is "c"
        maxArray = _.map data, (dataItem) -> +dataItem.h || 0
        minArray = _.map data, (dataItem) -> +dataItem.l || 0
      else
        # line chart uses dataL as a source. not data.
        dataL = _.map data, (dataItem) -> +dataItem.c || 0

    if not validColor.test color then color = "#000"
    # Accept dates as string and create date objects from it.
    dates = _.map rawDates, (rawDate) -> new Date(rawDate)
    # prefWidth is the width of column so that candles look good.
    range = Math.round (width - leftgutter)/prefWidth
    if range >= dataRange
      range = dataRange
    else
      currPos = dataRange - range

    gridRange = range
    # Create X-Axis labels from date array
    xlabels = _.map dates, (date) -> do date.getDate + "-" + months[do date.getMonth]

    # data can be plain numbers OR OHLC values.
    if typeof data[0] is "number" then type = "l"
    if type is "c" then gridRange = range + 2

    X = (width - leftgutter) / gridRange
    drawGrid leftgutter + X * .5, topgutter + .5, width - leftgutter - X, height - topgutter - bottomgutter, gridRange - 1, 8
    redraw.call @

  # Public method: move chart to left
  # It calls redraw. doesnt do much by itself.
  prev = (dx) ->
    if currPos is 0 then return
    if not (+dx >= 0) then dx = 1
    currPos = currPos - dx
    redraw.call @

  # Public method: move chart to right
  # It calls redraw. doesnt do much by itself.
  next = (dx) ->
    if currPos + range is data.length then return
    if not (+dx >= 0) then dx = 1
    currPos = currPos + dx
    redraw.call @

  # Return an object with public methods and variables
  # If new public methods/variables need to be published add them here.
  {paper: r, draw, prev, next, toString, reSize, setMessage, hover}
