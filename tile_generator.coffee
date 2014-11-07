$ ->
  canvas = $('#floor').get(0)
  ctx = canvas.getContext '2d'
  
  `function shuffle(sourceArray) {
     for (var n = 0; n < sourceArray.length - 1; n++) {
       var k = n + Math.floor(Math.random() * (sourceArray.length - n));

       var temp = sourceArray[k];
       sourceArray[k] = sourceArray[n];
       sourceArray[n] = temp;
     }
  }`
  
  _int = (name) ->
    parseInt($('#' + name).val(), 10)
    
  draw = ->
    ctx.clearRect(0, 0, canvas.width, canvas.height)
    tiles = ( {img: $(d).find('img').get(0), ratio: parseInt($(d).find('input').val(),10)} for d in $('.tile') ).filter (t) -> t.ratio > 0
  
    cols = _int('cols')
    rows = _int('rows')
    total_cells = cols * rows
    tsize = Math.min(canvas.width / cols, canvas.height / rows)
  
    tile_counts = (0 for tile in tiles)
    sample_ratios = (tile.ratio for tile in tiles)
    sample_total = sample_ratios.reduce (x, y) -> x + y
    sample_counts = (ratio * (Math.ceil(total_cells / sample_total)) for ratio in sample_ratios)
    wn = _int('wn')
  
    console.log(sample_counts)
    wc = (color) ->
      1 - (tile_counts[color] / sample_counts[color])
  
    grid = (->
      g = {}
      {
       get: (x, y) ->
         if x < 0 || x > (cols - 1) || y < 0 || y > (rows - 1)
           return -1
         return g["#{x},#{y}"] || -1
       set: (x, y, c) ->
         g["#{x},#{y}"] = c
      }
    )()
  
    pattern = (dx, dy, name, weight = 1) ->
      _cp = (dir, cell, color) ->
        count = 0
        [sx, sy] = [cell.x, cell.y]
        sx += (dx * dir)
        sy += (dy * dir)
        while grid.get(sx, sy) == color
          sx += (dx * dir)
          sy += (dy * dir)
          count += 1
        count
      _adj = (dir, cell, color) ->
        [sx, sy] = [cell.x, cell.y]
        sx += (dx * dir)
        sy += (dy * dir)
        if grid.get(sx, sy) == color
          1
        else
          0
  
      {
        score: (cell, color) ->
          {
            cp: ((_cp(1, cell, color) + _cp(-1, cell, color)) ** wn) * weight
            adj: _adj(1, cell, color) + _adj(-1, cell, color)
          }
      }
  
    ps = [
      pattern(1, 0, "horizontal", _int('wh'))
      pattern(0, 1, "vertical", _int('wv'))
      pattern(1, 1, "diagonal1", _int('wd1'))
      pattern(1, -1, "diagonal2", _int('wd2') )
    ]
  
    energy_base = (cell, color) ->
      pscores = (p.score(cell, color) for p in ps)
      t = (pscore.adj for pscore in pscores).reduce (x,y) -> x + y
      (pscore.cp * ((pscore.adj + 1) / (t + 1)) for pscore in pscores).reduce (x, y) -> x + y
  
    choose_color = (cell) ->
      ec = ({e: energy_base(cell, color), color: color} for tile, color in tiles).sort (a, b) -> a.e - b.e
      ecmax = ec[ec.length - 1]
      if ecmax.e <= 0
        foo.ep = wc(foo.color) for foo in ec
      else
          foo.ep = wc(foo.color) * (1 - (foo.e / ecmax.e)) for foo in ec
      ec.sort (a, b) -> a.ep - b.ep
      maxec = []
      for foo in ec
        if maxec.length == 0 || foo.ep == maxec[0].ep
          maxec.push(foo)
        if foo.ep > maxec[0].ep
          maxec = [foo]
      shuffle(maxec)
      cmin = maxec[0].color
      tile_counts[cmin] += 1
      grid.set(cell.x, cell.y, cmin)
      ctx.drawImage(tiles[cmin].img, cell.x * tsize, cell.y * tsize, tsize, tsize)
  
    cells = []
  
    for x in [0..(cols - 1)]
      for y in [0..(rows - 1)]
        cells.push({x: x, y: y})
  
    shuffle(cells)
   
    choose_color(cell) for cell in cells
    
  draw()
  $(window).load(draw) 
  $('#generate').click(draw)


