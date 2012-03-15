tokenRegex       = /\{([^\}]+)\}/g
objNotationRegex = /(?:(?:^|\.)(.+?)(?=\[|\.|$|\()|\[('|")(.+?)\2\])(\(\))?/g
replacer = (all, key, obj) ->
  res = obj
  key.replace objNotationRegex, (all, name, quote, quotedName, isFunc) ->
    name = name || quotedName
    if res
      if name of res
        res = res[name]
      typeof res == "function" && isFunc && (res = do res)
        
  res = (if res == null or res == obj then all else res) + ""
  res

fill = (str, obj) -> String(str).replace tokenRegex, (all, key) -> replacer all, key, obj

Raphael.fn.popup = (X, Y, set, pos, ret) ->
  pos = String(pos or "top-middle").split "-"
  pos[1] = pos[1] or "middle"
  r = 5
  bb = do set.getBBox
  w = (Math.round bb.width) + 0.5
  h = (Math.round bb.height)
  x = (Math.round bb.x) - r
  y = (Math.round bb.y) - r
  gap = Math.min h / 2, w / 2, 10
  shapes =
    top: "M{x},{y}h{w4},{w4},{w4},{w4}a{r},{r},0,0,1,{r},{r}v{h4},{h4},{h4},{h4}a{r},{r},0,0,1,-{r},{r}l-{right},0-{gap},{gap}-{gap}-{gap}-{left},0a{r},{r},0,0,1-{r}-{r}v-{h4}-{h4}-{h4}-{h4}a{r},{r},0,0,1,{r}-{r}z"

    bottom: "M{x},{y}l{left},0,{gap}-{gap},{gap},{gap},{right},0a{r},{r},0,0,1,{r},{r}v{h4},{h4},{h4},{h4}a{r},{r},0,0,1,-{r},{r}h-{w4}-{w4}-{w4}-{w4}a{r},{r},0,0,1-{r}-{r}v-{h4}-{h4}-{h4}-{h4}a{r},{r},0,0,1,{r}-{r}z"

    right: "M{x},{y}h{w4},{w4},{w4},{w4}a{r},{r},0,0,1,{r},{r}v{h4},{h4},{h4},{h4}a{r},{r},0,0,1,-{r},{r}h-{w4}-{w4}-{w4}-{w4}a{r},{r},0,0,1-{r}-{r}l0-{bottom}-{gap}-{gap},{gap}-{gap},0-{top}a{r},{r},0,0,1,{r}-{r}z"

    left: "M{x},{y}h{w4},{w4},{w4},{w4}a{r},{r},0,0,1,{r},{r}l0,{top},{gap},{gap}-{gap},{gap},0,{bottom}a{r},{r},0,0,1,-{r},{r}h-{w4}-{w4}-{w4}-{w4}a{r},{r},0,0,1-{r}-{r}v-{h4}-{h4}-{h4}-{h4}a{r},{r},0,0,1,{r}-{r}z"
  
  offset =
    hx0: X - (x + r + w - gap * 2)
    hx1: X - (x + r + w / 2 - gap)
    hx2: X - (x + r + gap)
    vhy: Y - (y + r + h + r + gap)
    "^hy": Y - (y - gap)
      
  mask = [
    x: x + r
    y: y
    w: w
    w4: w / 4
    h4: h / 4
    right: 0
    left: w - gap * 2
    bottom: 0
    top: h - gap * 2
    r: r
    h: h
    gap: gap
  , 
    x: x + r
    y: y
    w: w
    w4: w / 4
    h4: h / 4
    left: w / 2 - gap
    right: w / 2 - gap
    top: h / 2 - gap
    bottom: h / 2 - gap
    r: r
    h: h
    gap: gap
  ,
    x: x + r
    y: y
    w: w
    w4: w / 4
    h4: h / 4
    left: 0
    right: w - gap * 2
    top: 0
    bottom: h - gap * 2
    r: r
    h: h
    gap: gap
  ][if pos[1] is "middle" then 1 else (pos[1] is "top" or pos[1] is "left") * 2]
  dx = 0
  dy = 0
  out = @path(fill shapes[pos[0]], mask).insertBefore set
  switch pos[0]
    when "top"
      dx = X - (x + r + mask.left + gap)
      dy = Y - (y + r + h + r + gap);
                
    when "bottom"
      dx = X - (x + r + mask.left + gap)
      dy = Y - (y - gap)
                
    when "left"
      dx = X - (x + r + w + r + gap)
      dy = Y - (y + r + mask.top + gap)
                
    when "right"
      dx = X - (x - gap)
      dy = Y - (y + r + mask.top + gap)

  out.translate dx, dy
  if ret
    ret = out.attr "path"
    do out.remove
    return path: ret, dx: dx, dy: dy
  set.translate(dx, dy);
  out