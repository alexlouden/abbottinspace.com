(function () {
  var Bullet,
    Enemy,
    GRAVITY_THRESH,
    NEWTONS_G,
    Player,
    SpaceObject,
    generate_star_group,
    getRandom,
    height,
    resizeCanvas,
    width,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function (child, parent) {
      for (var key in parent) {
        if (__hasProp.call(parent, key)) child[key] = parent[key];
      }
      function ctor() {
        this.constructor = child;
      }
      ctor.prototype = parent.prototype;
      child.prototype = new ctor();
      child.__super__ = parent.prototype;
      return child;
    },
    __bind = function (fn, me) {
      return function () {
        return fn.apply(me, arguments);
      };
    };

  Array.prototype.remove = function () {
    var arg, args, index, output, _i, _len;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    output = [];
    for (_i = 0, _len = args.length; _i < _len; _i++) {
      arg = args[_i];
      index = this.indexOf(arg);
      if (index !== -1) {
        output.push(this.splice(index, 1));
      }
    }
    if (args.length === 1) {
      output = output[0];
    }
    return output;
  };

  getRandom = function (min, max) {
    return min + Math.floor(Math.random() * (max - min + 1));
  };

  width = $("#game").width();

  height = $("#game").height();

  NEWTONS_G = 5000;

  GRAVITY_THRESH = 100;

  generate_star_group = function () {
    var colour,
      glowamount,
      glowcolour,
      glowsize,
      group,
      i,
      layer,
      num_stars,
      size,
      x,
      y,
      _i;
    layer = new Kinetic.Layer();
    group = new Kinetic.Group();
    num_stars = getRandom(100, 200);
    for (
      i = _i = 0;
      0 <= num_stars ? _i <= num_stars : _i >= num_stars;
      i = 0 <= num_stars ? ++_i : --_i
    ) {
      x = Math.random() * width;
      y = Math.random() * height;
      size = Math.random() * 0.8;
      colour = "#ffffff";
      glowcolour = "#ffffff";
      glowsize = Math.random() * 30;
      glowamount = Math.random() * 0.8;
      group.add(
        new Kinetic.Circle({
          x: x,
          y: y,
          fillEnabled: false,
          radius: size,
          strokeWidth: size,
          stroke: colour,
          shadowColor: glowcolour,
          shadowBlur: glowsize * size,
          shadowOpacity: glowamount,
        })
      );
    }
    layer.add(group);
    return layer;
  };

  SpaceObject = (function () {
    function SpaceObject(name, width, height) {
      this.name = name;
      this.width = width;
      this.height = height;
      this.velocity = {
        x: 0,
        y: 0,
        rot: 0,
      };
      this.acceleration = {
        x: 0,
        y: 0,
        rot: 0,
      };
    }

    SpaceObject.prototype.makeShip = function (width, height) {
      this.ship = new Kinetic.Group();
    };

    SpaceObject.prototype.float = function (tdiff) {};

    return SpaceObject;
  })();

  Bullet = (function (_super) {
    var BULLET_ACC, BULLET_INIT_VEL;

    __extends(Bullet, _super);

    BULLET_ACC = 50;

    BULLET_INIT_VEL = 5;

    function Bullet(player) {
      var h, rot, x, xrot, y, yrot;
      h = 10;
      Bullet.__super__.constructor.call(this, "Bullet", 1, h);
      rot = player.ship.getRotation() - Math.PI / 2;
      x = player.ship.getX() - 100 * Math.cos(rot);
      y = player.ship.getY() - 100 * Math.sin(rot);
      if (x < 0) {
        x += width;
      }
      if (y < 0) {
        y += height;
      }
      this.line = new Kinetic.Line({
        points: [0, 0, 0, h],
        stroke: "white",
        strokeColourWidth: 2,
        strokeColourEnabled: true,
        shadowColor: "red",
        shadowBlur: 40,
        shadowOpacity: 1,
        lineCap: "round",
      });
      this.line.setX(x);
      this.line.setY(y);
      this.line.setRotation(player.ship.getRotation());
      this.line.gameobject = this;
      window.bulletlayer.add(this.line);
      this.velocity.x = player.velocity.x;
      this.velocity.y = player.velocity.y;
      xrot = Math.cos(this.line.getRotation() + Math.PI / 2);
      yrot = Math.sin(this.line.getRotation() + Math.PI / 2);
      this.velocity.x += BULLET_INIT_VEL * xrot;
      this.velocity.y += BULLET_INIT_VEL * yrot;
    }

    Bullet.prototype.step = function (frame) {
      var tdiff, xrot, yrot;
      tdiff = frame.timeDiff / 1000;
      xrot = Math.cos(this.line.getRotation() + Math.PI / 2);
      yrot = Math.sin(this.line.getRotation() + Math.PI / 2);
      this.acceleration.x = BULLET_ACC * xrot;
      this.acceleration.y = BULLET_ACC * yrot;
      this.velocity.x += this.acceleration.x * tdiff;
      this.velocity.y += this.acceleration.y * tdiff;
      this.line.setX(this.line.getX() + this.velocity.x);
      this.line.setY(this.line.getY() + this.velocity.y);
      this.handleIntersections({
        x: this.line.getX() + xrot * 10,
        y: this.line.getY() + yrot * 10,
      });
      if (
        this.line.getX() < -20 ||
        this.line.getY() < -20 ||
        this.line.getX() > width + 20 ||
        this.line.getY() > height + 20
      ) {
        return this.destroy();
      }
    };

    Bullet.prototype.handleIntersections = function (pos) {
      var gameobject, intersection;
      intersection = window.stage.getIntersection(pos);
      if (intersection && intersection.hasOwnProperty("shape")) {
        window.int = intersection;
        if (intersection.shape.hasOwnProperty("gameobject")) {
          gameobject = intersection.shape.gameobject;
          console.log(gameobject);
          if (gameobject.name === "Player") {
            console.log("You shot yourself");
          } else if (gameobject.name === "Enemy") {
            if (gameobject.polygon.getFill() === "green") {
              gameobject.polygon.setFill("red");
            } else {
              gameobject.polygon.setFill("green");
            }
          }
          return this.destroy();
        } else {
          return console.log(intersection);
        }
      }
    };

    Bullet.prototype.destroy = function () {
      window.player.bullets.remove(this);
      return this.line.remove();
    };

    return Bullet;
  })(SpaceObject);

  Enemy = (function (_super) {
    __extends(Enemy, _super);

    Enemy.prototype.FWD_ACC = 1;

    Enemy.prototype.ROT_ACC = 5;

    Enemy.prototype.mass = 10;

    function Enemy() {
      this.step = __bind(this.step, this);
      this.size = 50;
      Enemy.__super__.constructor.call(this, "Enemy", this.size, this.size);
      this.makeShip();
      this.ship.setX(width / 4);
      this.ship.setY(height / 2);
    }

    Enemy.prototype.makeShip = function () {
      this.ship = new Kinetic.Group();
      this.polygon = new Kinetic.Polygon({
        points: [
          [0, (-this.height * 2) / 3],
          [-this.width / 2, (this.height * 1) / 3],
          [0, (this.height * 1) / 5],
          [this.width / 2, (this.height * 1) / 3],
        ],
        fill: "#000000",
        strokeWidth: 3,
        stroke: "#ffffff",
      });
      this.ship.add(this.polygon);
      this.polygon.gameobject = this;
      return (this.ship.gameobject = this);
    };

    Enemy.prototype.step = function (frame) {
      var dx,
        dy,
        gravity_acceleration,
        gravity_direction,
        gravity_force,
        player_direction,
        rotation_offset,
        rsquared,
        tdiff;
      tdiff = frame.timeDiff / 1000;
      dx = player.ship.getX() - this.ship.getX();
      dy = player.ship.getY() - this.ship.getY();
      rsquared = dx * dx + dy * dy;
      gravity_force = (NEWTONS_G * (this.mass * player.mass)) / rsquared;
      if (gravity_force > GRAVITY_THRESH) {
        gravity_force = GRAVITY_THRESH;
      }
      gravity_acceleration = gravity_force / this.mass;
      gravity_direction = Math.atan2(dx, dy);
      this.acceleration.x += gravity_acceleration * Math.sin(gravity_direction);
      this.acceleration.y += gravity_acceleration * Math.cos(gravity_direction);
      player_direction = Math.PI - Math.atan2(dx, dy);
      rotation_offset = player_direction - this.ship.getRotation();
      this.velocity.rot = this.ROT_ACC * rotation_offset;
      this.velocity.x += this.acceleration.x * tdiff;
      this.velocity.y += this.acceleration.y * tdiff;
      this.velocity.rot += this.acceleration.rot * tdiff;
      this.velocity.x *= 0.95;
      this.velocity.y *= 0.95;
      this.ship.setX(this.ship.getX() + this.velocity.x);
      this.ship.setY(this.ship.getY() + this.velocity.y);
      this.ship.setRotationDeg(this.ship.getRotationDeg() + this.velocity.rot);
      if (this.ship.getY() < -this.size) {
        this.ship.setY(this.ship.getY() + height + this.size * 2);
      }
      if (this.ship.getY() > height + this.size) {
        this.ship.setY(this.ship.getY() - height - this.size * 2);
      }
      if (this.ship.getX() < -this.size) {
        this.ship.setX(this.ship.getX() + width + this.size * 2);
      }
      if (this.ship.getX() > width + this.size) {
        return this.ship.setX(this.ship.getX() - width - this.size * 2);
      }
    };

    return Enemy;
  })(SpaceObject);

  Player = (function (_super) {
    __extends(Player, _super);

    Player.prototype.forward = false;

    Player.prototype.backward = false;

    Player.prototype.left = false;

    Player.prototype.right = false;

    Player.prototype.shooting = false;

    Player.prototype.mass = 1;

    Player.prototype.FWD_ACC = 8;

    Player.prototype.ROT_ACC = 4;

    Player.prototype.BRAKE_STRENGTH = 0.9;

    Player.prototype.SHOOTING_FREQ = 100;

    function Player() {
      this.step = __bind(this.step, this);
      this.keyUpHandler = __bind(this.keyUpHandler, this);
      this.keyDownHandler = __bind(this.keyDownHandler, this);
      var imageObj;
      Player.__super__.constructor.call(this, "Player", 120, 210);
      imageObj = new Image();
      imageObj.onload = this.makeShip(this.width, this.height, imageObj);
      imageObj.src = "./images/abbottship.png";
      this.ship.setX(width / 2);
      this.ship.setY(height / 2);
      this.ship.setRotationDeg(180);
      this.ship.gameobject = this;
      this.ship.exhaust.gameobject = this;
      this.shipimg.gameobject = this;
      this.bullets = [];
      this.bullet_last_shot = 0;
    }

    Player.prototype.makeShip = function (width, height, img) {
      var exhaust;
      this.ship = new Kinetic.Group();
      this.ship.exhaust_tip = {
        x: 0,
        y: -height / 12 - 150,
      };
      this.ship.rad = Math.max(width, height);
      exhaust = new Kinetic.Shape({
        drawFunc: function (canvas) {
          var context, ship, top_left, top_right;
          ship = window.player.ship;
          context = canvas.getContext();
          top_left = {
            x: width / 8,
            y: -height / 12 - 65,
          };
          top_right = {
            x: -width / 8,
            y: -height / 12 - 65,
          };
          context.beginPath();
          context.moveTo(top_left.x, top_left.y);
          context.lineTo(top_right.x, top_left.y);
          context.bezierCurveTo(
            top_right.x,
            top_right.y,
            0,
            -height / 12 - 100,
            ship.exhaust_tip.x,
            ship.exhaust_tip.y
          );
          context.bezierCurveTo(
            ship.exhaust_tip.x,
            ship.exhaust_tip.y,
            0,
            -height / 12 - 100,
            top_left.x,
            top_left.y
          );
          context.closePath();
          return canvas.fill(this);
        },
        strokeEnabled: false,
        fill: "orange",
        shadowColor: "orange",
        shadowBlur: 10,
      });
      this.ship.add(exhaust);
      this.ship.exhaust = exhaust;
      this.ship.exhaust.hide;
      this.shipimg = new Kinetic.Image({
        image: img,
        x: width / 2,
        y: height / 2,
        width: width,
        height: height,
        rotationDeg: 180,
      });
      this.ship.add(this.shipimg);
      this.ship2 = this.makeFakeShip(img, exhaust.clone());
      this.ship3 = this.makeFakeShip(img, exhaust.clone());
      return (this.ship4 = this.makeFakeShip(img, exhaust.clone()));
    };

    Player.prototype.makeFakeShip = function (img, exhaust) {
      var image, ship;
      ship = new Kinetic.Group();
      ship.exhaust = exhaust;
      ship.exhaust.hide();
      ship.exhaust.gameobject = this;
      ship.add(exhaust);
      image = new Kinetic.Image({
        image: img,
        x: this.width / 2,
        y: this.height / 2,
        width: this.width,
        height: this.height,
        rotationDeg: 180,
      });
      ship.add(image);
      image.gameobject = this;
      ship.gameobject = this;
      ship.hide();
      return ship;
    };

    Player.prototype.keyDownHandler = function (event) {
      switch (event.which) {
        case 38:
          this.forward = true;
          break;
        case 40:
          this.backward = true;
          break;
        case 37:
          this.left = true;
          break;
        case 39:
          this.right = true;
          break;
        case 32:
          this.shooting = true;
          break;
        case 88:
          this.brake = true;
          break;
      }
    };

    Player.prototype.keyUpHandler = function (event) {
      switch (event.which) {
        case 38:
          this.forward = false;
          break;
        case 40:
          this.backward = false;
          break;
        case 37:
          this.left = false;
          break;
        case 39:
          this.right = false;
          break;
        case 32:
          this.shooting = false;
          break;
        case 88:
          this.brake = false;
      }
    };

    Player.prototype.step = function (frame) {
      var bullet,
        dx,
        dy,
        gravity_acceleration,
        gravity_direction,
        gravity_force,
        rsquared,
        tdiff,
        xrot,
        yrot,
        _i,
        _len,
        _ref,
        _results;
      tdiff = frame.timeDiff / 1000;
      xrot = Math.cos(this.ship.getRotation() + Math.PI / 2);
      yrot = Math.sin(this.ship.getRotation() + Math.PI / 2);
      if (this.forward) {
        this.acceleration.x = this.FWD_ACC * xrot;
        this.acceleration.y = this.FWD_ACC * yrot;
        this.ship.exhaust.show();
        this.ship2.exhaust.show();
        this.ship3.exhaust.show();
        this.ship4.exhaust.show();
      } else if (this.backward) {
        this.acceleration.x = -this.FWD_ACC * xrot;
        this.acceleration.y = -this.FWD_ACC * yrot;
        this.ship.exhaust.hide();
        this.ship2.exhaust.hide();
        this.ship3.exhaust.hide();
        this.ship4.exhaust.hide();
      } else {
        this.acceleration.x = 0;
        this.acceleration.y = 0;
        this.ship.exhaust.hide();
        this.ship2.exhaust.hide();
        this.ship3.exhaust.hide();
        this.ship4.exhaust.hide();
      }
      if (this.left) {
        this.acceleration.rot = -this.ROT_ACC;
      } else if (this.right) {
        this.acceleration.rot = this.ROT_ACC;
      } else {
        this.acceleration.rot = 0;
      }
      if (this.brake) {
        this.velocity.x *= this.BRAKE_STRENGTH;
        this.velocity.y *= this.BRAKE_STRENGTH;
        this.velocity.rot *= this.BRAKE_STRENGTH;
      }
      dx = enemy.ship.getX() - this.ship.getX();
      dy = enemy.ship.getY() - this.ship.getY();
      rsquared = dx * dx + dy * dy;
      gravity_force = (NEWTONS_G * (this.mass * enemy.mass)) / rsquared;
      if (gravity_force > GRAVITY_THRESH) {
        gravity_force = GRAVITY_THRESH;
      }
      gravity_acceleration = gravity_force / this.mass;
      gravity_direction = Math.atan2(dx, dy);
      this.acceleration.x += gravity_acceleration * Math.sin(gravity_direction);
      this.acceleration.y += gravity_acceleration * Math.cos(gravity_direction);
      this.velocity.x += this.acceleration.x * tdiff;
      this.velocity.y += this.acceleration.y * tdiff;
      this.velocity.rot += this.acceleration.rot * tdiff;
      this.ship.exhaust_tip.x = -40 * Math.sin(this.velocity.rot / 3);
      this.ship.setX(this.ship.getX() + this.velocity.x);
      this.ship.setY(this.ship.getY() + this.velocity.y);
      this.ship.setRotationDeg(this.ship.getRotationDeg() + this.velocity.rot);
      if (this.ship.getX() < this.width) {
        this.ship2.show();
        this.ship2.setX(this.ship.getX() + width);
        this.ship2.setY(this.ship.getY());
        this.ship2.setRotation(this.ship.getRotation());
      } else {
        this.ship2.hide();
      }
      if (this.ship.getY() < this.ship.rad) {
        this.ship3.show();
        this.ship3.setX(this.ship.getX());
        this.ship3.setY(this.ship.getY() + height);
        this.ship3.setRotation(this.ship.getRotation());
      } else {
        this.ship3.hide();
      }
      if (
        this.ship.getY() < this.ship.rad &&
        this.ship.getX() < this.ship.rad
      ) {
        this.ship4.show();
        this.ship4.setX(this.ship.getX() + width);
        this.ship4.setY(this.ship.getY() + height);
        this.ship4.setRotation(this.ship.getRotation());
      } else {
        this.ship4.hide();
      }
      if (this.ship.getX() < -this.ship.rad) {
        this.ship.setX(this.ship.getX() + width);
      }
      if (this.ship.getY() < -this.ship.rad) {
        this.ship.setY(this.ship.getY() + height);
      }
      if (this.ship.getX() > width - this.ship.rad) {
        this.ship.setX(this.ship.getX() - width);
      }
      if (this.ship.getY() > height - this.ship.rad) {
        this.ship.setY(this.ship.getY() - height);
      }
      if (this.shooting) {
        this.handle_bullets(frame);
      }
      _ref = this.bullets;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        bullet = _ref[_i];
        if (bullet) {
          _results.push(bullet.step(frame));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    Player.prototype.handle_bullets = function (frame) {
      var bullet;
      if (frame.time - this.bullet_last_shot > this.SHOOTING_FREQ) {
        this.bullet_last_shot = frame.time;
        bullet = new Bullet(this);
        return this.bullets.push(bullet);
      }
    };

    return Player;
  })(SpaceObject);

  window.onload = function () {
    var anim, layer, player, root, stage, stars;
    stage = new Kinetic.Stage({
      container: "game",
      width: width,
      height: height,
    });
    player = new Player();
    root = typeof exports !== "undefined" && exports !== null ? exports : this;
    root.player = player;
    root.anim = anim;
    root.stage = stage;
    stars = generate_star_group();
    stage.add(stars);
    layer = new Kinetic.Layer();
    layer.add(player.ship);
    layer.add(player.ship2);
    layer.add(player.ship3);
    layer.add(player.ship4);
    root.enemy = new Enemy();
    layer.add(root.enemy.ship);
    root.bulletlayer = layer;
    stage.add(layer);
    anim = new Kinetic.Animation(function (frame) {
      player.step(frame);
      return enemy.step(frame);
    }, layer);
    anim.start();
    $(document).keydown(player.keyDownHandler);
    return $(document).keyup(player.keyUpHandler);
  };

  resizeCanvas = function () {
    $("canvas").width("100%").height("100%");
    return $(".kineticjs-content").width("100%").height("100%");
  };

  window.onresize = function () {
    return resizeCanvas();
  };
}.call(this));
