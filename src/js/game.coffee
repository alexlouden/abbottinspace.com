
getRandom = (min, max) ->
  min + Math.floor(Math.random() * (max - min + 1))

# canvas dimensions
width = $("#game").width()
height = $("#game").height()

generate_star_group = ->
  layer = new Kinetic.Layer()
  group = new Kinetic.Group()
  
  num_stars = getRandom(100, 200)
  
  for i in [0..num_stars]
    x = Math.random() * width
    y = Math.random() * height
    size = Math.random() * 0.8
    colour = "#ffffff"
    
    glowcolour = '#ffffff'
    glowsize = Math.random() * 30
    glowamount = Math.random() * 0.8
    
    group.add new Kinetic.Circle(
      x: x
      y: y
      fillEnabled: false
      radius: size
      strokeWidth: size
      stroke: colour
      shadowColor: glowcolour
      shadowBlur: glowsize*size
      shadowOpacity: glowamount
    )
  
  layer.add group
  return layer

class SpaceShip
  
  constructor: (name, width, height) ->
    @name = name
    @width = width
    @height = height
    
    @velocity =
      x: 0
      y: 0
      rot: 0

    @acceleration =
      x: 0
      y: 0
      rot: 0
    
  makeShip: (width, height) ->
    @ship = new Kinetic.Group()
    return
    
  float: (tdiff) ->
            

class Player extends SpaceShip
  @forward = false
  @backward = false
  @left = false
  @right = false
  @shooting = false
  
  FWD_ACC = 4 # px/s
  ROT_ACC = 8 # deg/s
  BRAKE_STRENGTH = 0.90
  
  constructor: ->
    super("Human", 30, 50)
    
    imageObj = new Image()
    imageObj.onload = @makeShip(@width, @height, imageObj)
    imageObj.src = '/images/abbottship.png'
    
    @ship.setX width / 2
    @ship.setY height / 2
    @ship.setRotationDeg 180
    
  makeShip: (width, height, img) ->
    @ship = new Kinetic.Group()
    
    # Draw exhaust
    exhaust = new Kinetic.Shape(
      drawFunc: (canvas) ->
        context = canvas.getContext()
        context.beginPath()
        context.moveTo(width/2,  -height/3-65)  # top left
        context.lineTo(-width/2, -height/3-65) # top right
        context.bezierCurveTo(
          -width/2, -height/3 - 65,
          0,        -height/3 - 100,
          0,        -height/3 - 150
        )
        context.bezierCurveTo(
          0,        -height/3 - 150,
          0,        -height/3 - 100,
          width/2,  -height/3 - 65
        )
        context.closePath()
        canvas.fill(this)
      strokeEnabled: false
      fill: 'orange'
      shadowColor: 'orange'
      shadowBlur: 10
    )
    @ship.add exhaust
    @ship.exhaust = exhaust
    @ship.exhaust.hide()
    
    # Draw ship
    imgsize = [120, 210]
    @ship.add new Kinetic.Image(
      image: img
      x: imgsize[0]/2
      y: imgsize[1]/2
      width: imgsize[0]
      height: imgsize[1]
      rotationDeg: 180
    )
    
    
  keyDownHandler: (event) =>
    switch event.which
      when 38 then @forward = true
      when 40 then @backward = true
      when 37 then @left = true
      when 39 then @right = true
      when 32 then @shooting = true  # space
      when 88 then @brake = true     # x
      else
        console.log event.which
    return
    
  keyUpHandler: (event) =>
    switch event.which
      when 38 then @forward = false
      when 40 then @backward = false
      when 37 then @left = false
      when 39 then @right = false
      when 32 then @shooting = false
      when 88 then @brake = false
    return
  
  step: (tdiff) =>
    xrot = Math.cos(@ship.getRotation() + Math.PI / 2)
    yrot = Math.sin(@ship.getRotation() + Math.PI / 2)
    
    # acc
    if @forward
      @acceleration.x = FWD_ACC * xrot
      @acceleration.y = FWD_ACC * yrot
    else if @backward
      @acceleration.x = -FWD_ACC * xrot
      @acceleration.y = -FWD_ACC * yrot
    else
      @acceleration.x = 0
      @acceleration.y = 0
        
    if @left
      @acceleration.rot = -ROT_ACC
    else if @right
      @acceleration.rot = ROT_ACC
    else
      @acceleration.rot = 0
    
    if @brake
      @velocity.x *= BRAKE_STRENGTH # todo add tdiff as a factor
      @velocity.y *= BRAKE_STRENGTH
      @velocity.rot *= BRAKE_STRENGTH
    
    # vel
    @velocity.x += @acceleration.x * tdiff
    @velocity.y += @acceleration.y * tdiff
    @velocity.rot += @acceleration.rot * tdiff

    # pos
    @ship.setX @ship.getX() + @velocity.x
    @ship.setY @ship.getY() + @velocity.y
    @ship.setRotationDeg @ship.getRotationDeg() + @velocity.rot

    # wrap
    if @ship.getX() < -@height / 2
      @ship.setX @ship.getX() + width + 100  # left
    if @ship.getY() < -@height / 2
      @ship.setY @ship.getY() + height + 100  # top
    if @ship.getX() > width + @height
      @ship.setX @ship.getX() - width - 100   # right
    if @ship.getY() > height + @height
      @ship.setY @ship.getY() - height - 100  # bottom
    

window.onload = ->
    
  stage = new Kinetic.Stage(
    container: "game"
    width: width
    height: height
  )
  
  player = new Player()
  
  # put player in global scope for testing
  root = exports ? this
  root.player = player
  root.anim = anim
  root.stage = stage
  
  stars = generate_star_group()
  stage.add stars
  
  layer = new Kinetic.Layer()
  layer.add player.ship
  stage.add layer
  
  anim = new Kinetic.Animation((frame) ->
    tdiff = frame.timeDiff / 1000
    player.step tdiff
  , layer)
  anim.start()
  
  $(document).keydown player.keyDownHandler
  $(document).keyup player.keyUpHandler