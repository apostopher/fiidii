jQuery ->
  scrips = []
  configfiidii = holder: "chartholder", height: 550
  fiidiigraph = bgraph configfiidii
  r       =   fiidiigraph.paper
  label   =   do r.set
  label_visible = false
  leave_timer = 0
  months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  txt         =
    font         : '12px Helvetica, Arial', "font-weight": "bold"
    fill         : "#db2129"
  txt1        =
    font         : '10px Helvetica, Arial'
    fill         : "#666"

  label.push (r.text 60, 12, "Rs.").attr txt
  label.push (r.text 60, 27, "date").attr txt1
  do label.hide
  frame = (r.popup 100, 100, label, "right").attr(fill: "#fff", stroke: "#db2129", "stroke-width": 1, "fill-opacity": 1).hide()

  getScrips = (defaultScrip) ->
    $.ajax
      type: "GET"
      url: "/serverscripts/getScrips.php"
      dataType: "json"
      success: (response) ->
        scrips = response.scrips
        scripList = ($ "#searchterm").autocomplete
          minLength: 3
          delay: 100
          source: (req, res) ->
            srchExp = new RegExp "^" + req.term + ".*", "i"
            matches = []
            for scrip in scrips
              if (scrip.value.search srchExp) >= 0 or (scrip.label.search srchExp) >= 0
                matches.push scrip
            res matches

          focus: (event, ui) ->
            ($ "#searchterm").val ui.item.value
            false
          select: (event, ui) ->
            ($ "#searchterm").val ui.item.value
            false
        scripList.data("autocomplete")._renderItem = ( ul, item ) ->
          ($ "<li></li>").data("item.autocomplete", item).append("<a>" + item.label + "<br><span class=\"ui-item-symbol\">" + item.value + "</span></a>").appendTo ul

        if defaultScrip? then getCandles defaultScrip

  getCandles = (scrip) ->
    $.ajax
      type: "GET"
      url: "/serverscripts/candles.php"
      data: {scrip: scrip}
      dataType: "json"
      beforeSend: ->
        fiidiigraph.setMessage "Loading " + scrip
      success: (response) ->
        dates   =   []
        data    =   []

        for own key, val of response.data
          dates.unshift val.date
          data.unshift  o: +val.o, h: +val.h, l: +val.l, c: +val.c

        fiidiioptions =
          data      :  data
          dates     :  dates
          xtext     :  "dates"
          ytext     :  "Rs."
          type      :  "c"
          color     :  "#db2129"

        fiidiigraph.hover (rect, dot, data, date) ->
          rect.attr opacity: 0.04
          ###
          clearTimeout leave_timer
          label[0].attr text: data.c + " " + "Rs."
          label[1].attr text: do date.getDate + "-" + months[do date.getMonth]
          side = "right"
          side = "left"  if (dot.attr "cx") + frame.getBBox().width > r.width
          ppp = r.popup (dot.attr "cx"), (dot.attr "cy"), label, side, 1
          frame.show().stop().animate {path: ppp.path}, 200 * label_visible
          label.show().stop().animateWith frame, {translation: [ppp.dx, ppp.dy]}, 200 * label_visible
          dot.attr "r", 6
          label_visible = true
          do frame.toFront
          do label.toFront
          ###
        ,(rect, dot, data, date) ->
          rect.attr opacity: 0
          ###
          dot.attr "r", 4
          leave_timer = setTimeout ->
                        do frame.hide
                        do label.hide
                        label_visible = false
                    ,   1
          ###
        if fiidiigraph.draw fiidiioptions
          do frame.toFront
          do label.toFront
          scripName = ""
          for scripObj in scrips
            if scripObj.value is do scrip.toUpperCase
              scripName = scripObj.label

          ($ "#scripname").html scripName
          ($ document).keydown (e) ->
            if e.keyCode is 37
              do fiidiigraph.prev
              return false

            if e.keyCode is 39
              do fiidiigraph.next
              return false
            return true

          ($ window).resize ->
            do fiidiigraph.reSize
        else
          ($ "#scripname").html ""

        true
      failure: (response) ->
    true
  submitFrm = ->
    scripSymbol = do ($ "#searchterm").val
    if scripSymbol
      getCandles scripSymbol
    true

  ($ "#searchbtn").click submitFrm
  ($ '#searchterm').keydown (event) ->
    if event.keyCode is 13
      do submitFrm

  getScrips "NIFTY"
