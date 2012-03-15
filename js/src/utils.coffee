 map = (obj, iterator, context) ->
  results = []
  nativeMap = Array.prototype.map

  if obj is null then return results
  if nativeMap and obj.map is nativeMap then return obj.map iterator, context
  
  iterator.call null, value, index for value, index in obj
  

