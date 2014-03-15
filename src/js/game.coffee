Array.prototype.remove = (args...) ->
  output = []
  for arg in args
    index = @indexOf arg
    output.push @splice(index, 1) if index isnt -1
  output = output[0] if args.length is 1
  output

getRandom = (min, max) ->
  min + Math.floor(Math.random() * (max - min + 1))

# TODOS
# Add motion and gravity to enemy
# Add enemy/ship collisions
# Make ship explode on hit
# Spawn multiple enemies


# canvas dimensions
width = $("#game").width()
height = $("#game").height()

NEWTONS_G = 5000
GRAVITY_THRESH = 100

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

class Bullet extends SpaceShip
  BULLET_ACC = 50
  BULLET_INIT_VEL = 5
  
  constructor: (player) ->
    h = 10
    super("Bullet", 1, h)
    
    rot = player.ship.getRotation() - Math.PI/2
    x = player.ship.getX() - 100 * Math.cos(rot)
    y = player.ship.getY() - 100 * Math.sin(rot)
    
    if x < 0
      x += width
    if y < 0
      y += height
    
    @line = new Kinetic.Line(
      points: [0, 0, 0, h]
      stroke: 'white'
      strokeWidth: 2
      strokeEnabled: true
      shadowColor: 'red'
      shadowBlur: 40
      shadowOpacity: 1
      lineCap: 'round'
    )
    @line.setX(x)
    @line.setY(y)
    @line.setRotation(player.ship.getRotation())
    @line.gameobject = this
    window.bulletlayer.add @line
    
    @velocity.x = player.velocity.x
    @velocity.y = player.velocity.y
    
    xrot = Math.cos(@line.getRotation() + Math.PI / 2)
    yrot = Math.sin(@line.getRotation() + Math.PI / 2)
    
    @velocity.x += BULLET_INIT_VEL * xrot
    @velocity.y += BULLET_INIT_VEL * yrot
  
  step: (frame) ->
    tdiff = frame.timeDiff / 1000
    
    xrot = Math.cos(@line.getRotation() + Math.PI / 2)
    yrot = Math.sin(@line.getRotation() + Math.PI / 2)
    
    @acceleration.x = BULLET_ACC * xrot
    @acceleration.y = BULLET_ACC * yrot
    
    @velocity.x += @acceleration.x * tdiff
    @velocity.y += @acceleration.y * tdiff
    
    @line.setX @line.getX() + @velocity.x
    @line.setY @line.getY() + @velocity.y

    @handleIntersections(
      x: @line.getX() + xrot * 10
      y: @line.getY() + yrot * 10
    )
    
    # Out of bounds
    if (@line.getX() < -20 or
    @line.getY() < -20 or
    @line.getX() > width + 20 or
    @line.getY() > height + 20)
      @destroy()
  
  handleIntersections: (pos) ->
    intersection = window.stage.getIntersection(pos)
    # Intersected something that has a shape
    if intersection and intersection.hasOwnProperty('shape')
      window.int = intersection
      
      if intersection.shape.hasOwnProperty('gameobject')
        gameobject = intersection.shape.gameobject
        
        console.log gameobject
        if gameobject.name == 'Human'
          console.log 'You shot yourself'
        else if gameobject.name == 'Enemy'
          if gameobject.circle.getFill() == 'green'
            gameobject.circle.setFill('red')
          else
            gameobject.circle.setFill('green')
        
        @destroy()
        
      else
        console.log intersection
  
  destroy: ->
    window.player.bullets.remove(this)
    @line.remove()

class Enemy extends SpaceShip
  FWD_ACC: 1
  mass: 10
  
  constructor: ->
    @size = 50
    super("Enemy", @size, @size)
    @makeShip(@size)
    @ship.setX(width/4)
    @ship.setY(height/2)
  
  makeShip: (radius) ->
    @ship = new Kinetic.Group()
    
    @circle = new Kinetic.Circle(
      x: 0
      y: 0
      fill: 'green'
      radius: radius
    )
    @circle.gameobject = this
    @ship.add @circle
    @ship.gameobject = this

  step: (frame) =>
    tdiff = frame.timeDiff / 1000

    # gravity
    dx = player.ship.getX() - @ship.getX()
    dy = player.ship.getY() - @ship.getY()
    rsquared = (dx * dx) + (dy * dy)
    gravity_force = NEWTONS_G * (@mass * player.mass) / rsquared
    if gravity_force > GRAVITY_THRESH
      gravity_force = GRAVITY_THRESH
    gravity_acceleration = gravity_force / @mass
    gravity_direction = Math.atan2(dx, dy)
    @acceleration.x += gravity_acceleration * Math.sin(gravity_direction)
    @acceleration.y += gravity_acceleration * Math.cos(gravity_direction)

    # vel
    @velocity.x += @acceleration.x * tdiff # should it be /tdiff?
    @velocity.y += @acceleration.y * tdiff
    @velocity.rot += @acceleration.rot * tdiff

    # friction
    @velocity.x *= 0.95
    @velocity.y *= 0.95

    # pos
    @ship.setX @ship.getX() + @velocity.x
    @ship.setY @ship.getY() + @velocity.y
    @ship.setRotationDeg @ship.getRotationDeg() + @velocity.rot
    
    # wrap top
    if @ship.getY() < - @size
      @ship.setY @ship.getY() + height + @size * 2

    # wrap bottom
    if @ship.getY() > height + @size
      @ship.setY @ship.getY() - height - @size * 2

    # wrap left
    if @ship.getX() < - @size
      @ship.setX @ship.getX() + width + @size * 2

    # wrap right
    if @ship.getX() > width + @size
      @ship.setX @ship.getX() - width - @size * 2





class Player extends SpaceShip
  forward: false
  backward: false
  left: false
  right: false
  shooting: false
  
  mass: 1

  FWD_ACC: 8 # px/s
  ROT_ACC: 4 # deg/s
  BRAKE_STRENGTH: 0.90
  SHOOTING_FREQ: 100
  
  constructor: ->
    super("Player", 120, 210)
    
    imageObj = new Image()
    imageObj.onload = @makeShip(@width, @height, imageObj)
    imageObj.src = '/images/abbottship.png'
    
    @ship.setX width / 2
    @ship.setY height / 2
    @ship.setRotationDeg 180
    @ship.gameobject = this
    @ship.exhaust.gameobject = this
    @shipimg.gameobject = this
    
    @bullets = []
    @bullet_last_shot = 0
  
  makeShip: (width, height, img) ->
    @ship = new Kinetic.Group()
    
    @ship.exhaust_tip = {x: 0, y: -height/12 - 150}
    @ship.rad = Math.max(width, height)
    
    # Draw exhaust
    exhaust = new Kinetic.Shape(
      drawFunc: (canvas) ->
        ship = window.player.ship
        context = canvas.getContext()

        top_left = {x: width/8, y: -height/12 - 65}
        top_right = {x: -width/8, y: -height/12 - 65}
        
        context.beginPath()
        context.moveTo(top_left.x, top_left.y)
        context.lineTo(top_right.x, top_left.y)
        context.bezierCurveTo(
          top_right.x,        top_right.y,
          0,                  -height/12 - 100,
          ship.exhaust_tip.x, ship.exhaust_tip.y
        )
        context.bezierCurveTo(
          ship.exhaust_tip.x, ship.exhaust_tip.y,
          0,                  -height/12 - 100,
          top_left.x,         top_left.y,
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
    @ship.exhaust.hide
    
    # Draw ship
    @shipimg = new Kinetic.Image(
      image: img
      x: width/2
      y: height/2
      width: width
      height: height
      rotationDeg: 180
    )
    @ship.add @shipimg
    
    @ship2 = @makeFakeShip(img, exhaust.clone())
    @ship3 = @makeFakeShip(img, exhaust.clone())
    @ship4 = @makeFakeShip(img, exhaust.clone())
  
  makeFakeShip: (img, exhaust) ->
    
    ship = new Kinetic.Group()
    
    ship.exhaust = exhaust
    ship.exhaust.hide()
    ship.exhaust.gameobject = this
    
    ship.add exhaust
    image = new Kinetic.Image(
      image: img
      x: @width/2
      y: @height/2
      width: @width
      height: @height
      rotationDeg: 180
    )
    ship.add image
    image.gameobject = this
    ship.gameobject = this
    ship.hide()
    ship
  
  keyDownHandler: (event) =>
    switch event.which
      when 38 then @forward = true
      when 40 then @backward = true
      when 37 then @left = true
      when 39 then @right = true
      when 32 then @shooting = true  # space
      when 88 then @brake = true     # x
      else
        # console.log event.which
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
  
  step: (frame) =>
    tdiff = frame.timeDiff / 1000
    
    xrot = Math.cos(@ship.getRotation() + Math.PI / 2)
    yrot = Math.sin(@ship.getRotation() + Math.PI / 2)
    
    # acc
    if @forward
      @acceleration.x = @FWD_ACC * xrot
      @acceleration.y = @FWD_ACC * yrot
      @ship.exhaust.show()
      @ship2.exhaust.show()
      @ship3.exhaust.show()
      @ship4.exhaust.show()
    else if @backward
      @acceleration.x = -@FWD_ACC * xrot
      @acceleration.y = -@FWD_ACC * yrot
      @ship.exhaust.hide()
      @ship2.exhaust.hide()
      @ship3.exhaust.hide()
      @ship4.exhaust.hide()
    else
      @acceleration.x = 0
      @acceleration.y = 0
      @ship.exhaust.hide()
      @ship2.exhaust.hide()
      @ship3.exhaust.hide()
      @ship4.exhaust.hide()
      
    if @left
      @acceleration.rot = -@ROT_ACC
    else if @right
      @acceleration.rot = @ROT_ACC
    else
      @acceleration.rot = 0
    
    if @brake
      @velocity.x *= @BRAKE_STRENGTH # todo add tdiff as a factor
      @velocity.y *= @BRAKE_STRENGTH
      @velocity.rot *= @BRAKE_STRENGTH
    
    # gravity
    dx = enemy.ship.getX() - @ship.getX()
    dy = enemy.ship.getY() - @ship.getY()
    rsquared = (dx * dx) + (dy * dy)
    gravity_force = NEWTONS_G * (@mass * enemy.mass) / rsquared
    if gravity_force > GRAVITY_THRESH
      gravity_force = GRAVITY_THRESH
    gravity_acceleration = gravity_force / @mass
    gravity_direction = Math.atan2(dx, dy)
    @acceleration.x += gravity_acceleration * Math.sin(gravity_direction)
    @acceleration.y += gravity_acceleration * Math.cos(gravity_direction)

    # vel
    @velocity.x += @acceleration.x * tdiff # should it be /tdiff?
    @velocity.y += @acceleration.y * tdiff
    @velocity.rot += @acceleration.rot * tdiff

    @ship.exhaust_tip.x = - 40 * Math.sin @velocity.rot/3

    # pos
    @ship.setX @ship.getX() + @velocity.x
    @ship.setY @ship.getY() + @velocity.y
    @ship.setRotationDeg @ship.getRotationDeg() + @velocity.rot

    # wrap left
    if @ship.getX() < @width
      @ship2.show()
      @ship2.setX @ship.getX() + width
      @ship2.setY @ship.getY()
      @ship2.setRotation @ship.getRotation()
    # wrap right
    else
      @ship2.hide()
    
    # wrap top
    if @ship.getY() < @ship.rad
      @ship3.show()
      @ship3.setX @ship.getX()
      @ship3.setY @ship.getY() + height
      @ship3.setRotation @ship.getRotation()
    else
      @ship3.hide()
      
    if @ship.getY() < @ship.rad and @ship.getX() < @ship.rad
      @ship4.show()
      @ship4.setX @ship.getX() + width
      @ship4.setY @ship.getY() + height
      @ship4.setRotation @ship.getRotation()
    else
      @ship4.hide()
      
    if @ship.getX() < -@ship.rad
      @ship.setX @ship.getX() + width   # left
    if @ship.getY() < -@ship.rad
      @ship.setY @ship.getY() + height  # top
    if @ship.getX() > width - @ship.rad
      @ship.setX @ship.getX() - width   # right
    if @ship.getY() > height - @ship.rad
      @ship.setY @ship.getY() - height  # bottom
    
    # bullets
    if @shooting
      @handle_bullets frame
    
    for bullet in @bullets
      if bullet
        bullet.step frame
  
  handle_bullets: (frame) ->
        
    if frame.time - @bullet_last_shot > @SHOOTING_FREQ
      @bullet_last_shot = frame.time
      
      bullet = new Bullet(this)
      @bullets.push bullet
      
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
  layer.add player.ship2
  layer.add player.ship3
  layer.add player.ship4
  
  root.enemy = new Enemy()
  layer.add root.enemy.ship
  
  root.bulletlayer = layer
  stage.add layer
  
  anim = new Kinetic.Animation((frame) ->
    player.step frame
    enemy.step frame
  , layer)
  anim.start()
  
  $(document).keydown player.keyDownHandler
  $(document).keyup player.keyUpHandler
  
resizeCanvas = ->
  $('canvas').width('100%').height('100%')
  $('.kineticjs-content').width('100%').height('100%')

window.onresize = ->
  resizeCanvas()