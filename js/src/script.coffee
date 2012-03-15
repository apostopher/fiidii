sortedFiiData = null
sortedDiiData = null
sortedFiiDiiData = null
sortedNiftyData = null
sortedCurrData = null
loadGraph = new BGraph holder: "chartcontent", height: 500, type: "l"
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
  
  loadGraph.setHoverLabels null, '#{y} thousand crores'
  sortedData = prepareData response.d, "x"
  loadGraph.setData sortedData, "x", "y"
  
  sortedCurrData = prepareData response.c, "x"
  #Load currency values
  latestRates = sortedCurrData.slice(-1)[0]
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

  loadGraph.draw false

  ##Add click handlers
  $("#charttypefrm").submit (eventObj) ->
    charttype = $("#charttypebox").val()
    chartrange = 0 - $("#chartrangebox").val() || undefined
    switch charttype
      when "fii"
        loadGraph.setHoverLabels null, '#{y} thousand crores'
        if not sortedFiiData
          sortedFiiData = prepareData response.d, "x"
        loadGraph.setData sortedFiiData, "x", "f", "fii"
        ($ "#chartname").html "FII investment chart"
        ($ "#charthelp").html "Data is in thousand crore ( 10 billion ) indian Rupees."

      when "dii"
        loadGraph.setHoverLabels null, '#{y} thousand crores'
        if not sortedDiiData
          sortedDiiData = prepareData response.d, "x"
        loadGraph.setData sortedDiiData, "x", "d", "dii"
        ($ "#chartname").html "DII investment chart"
        ($ "#charthelp").html "Data is in thousand crore ( 10 billion ) indian Rupees."

      when "fiidii"
        loadGraph.setHoverLabels null, '#{y} thousand crores'
        if not sortedFiiDiiData
          sortedFiiDiiData = prepareData response.d, "x"
        loadGraph.setData sortedFiiDiiData, "x", "y", "fiidii"
        ($ "#chartname").html "FII + DII investment chart"
        ($ "#charthelp").html "Data is in thousand crore ( 10 billion ) indian Rupees."

      when "nifty"
        loadGraph.setHoverLabels null, '#{y}'
        if not sortedNiftyData
          sortedNiftyData = prepareData response.i, "x"
        loadGraph.setData sortedNiftyData, "x", "y", "nifty"
        ($ "#chartname").html "Nifty index chart"
        ($ "#charthelp").html "Data is NSE Nifty index value."

      when "curr"
        loadGraph.setHoverLabels null, '#{y} Rupees = 1 USD'
        loadGraph.setData sortedCurrData, "x", "u", "curr"
        ($ "#chartname").html "US $ currency chart"
        ($ "#charthelp").html "Data is in Indian Rupees per USA dollar."
        
    if chartrange
      loadGraph.draw false, chartrange
    else
      loadGraph.draw false
    false
  
  ($ "#twitterfollow").click (eventObj) ->
    do eventObj.preventDefault
    do eventObj.stopPropagation
    return false
