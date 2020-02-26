local deque = require 'lib.deque'


local game = {}

local WALL_THICKNESS = 1.0
local GRAVITY = 9.81 / 2
local bricks = {}

local breaks = 0
local drops = 0
local time = 0.0

local function won()
  return breaks == #bricks
end

local function reset()
  -- bricks
  for i, b in ipairs(bricks) do
    b:getBody():destroy()
  end
  bricks = {}
  local MARGIN = 8
  local HEIGHT = math.floor(BOUNDS_HEIGHT / 3)
  for j = -BOUNDS_HEIGHT / 2 + MARGIN, -BOUNDS_HEIGHT / 2 + HEIGHT do
    local i = -BOUNDS_WIDTH / 2
    while i < BOUNDS_WIDTH / 2 do
      local nexti = math.min(i + math.random(8), BOUNDS_WIDTH / 2)
      local randw = nexti - i
      local shapeBrick = love.physics.newRectangleShape(randw, 1)
      local posB = love.physics.newBody(world, i + randw / 2, j, "static")
      i = nexti
      local fixture = love.physics.newFixture(posB, shapeBrick)
      fixture:setUserData("brick")
      table.insert(bricks, fixture)
    end
  end
  -- vars
  breaks = 0
  drops = 0
  time = 0.0
  -- objects
  posP:setPosition(0, 0)
  posBall:setPosition(0, 0)
  posBall:setLinearVelocity(0, 0)
end

function game:init()
  world = love.physics.newWorld(0, GRAVITY * love.physics.getMeter(), true)
  -- boundaries
  shapeX = love.physics.newRectangleShape(BOUNDS_WIDTH, WALL_THICKNESS)
  shapeY = love.physics.newRectangleShape(WALL_THICKNESS, BOUNDS_HEIGHT)
  posTop    = love.physics.newBody(world, 0, -BOUNDS_HEIGHT/2, "static")
  posBottom = love.physics.newBody(world, 0, BOUNDS_HEIGHT/2, "static")
  posLeft   = love.physics.newBody(world, -BOUNDS_WIDTH/2, 0, "static")
  posRight  = love.physics.newBody(world, BOUNDS_WIDTH/2, 0, "static")
  wallTop = love.physics.newFixture(posTop, shapeX)
  wallLeft = love.physics.newFixture(posLeft, shapeY)
  wallRight = love.physics.newFixture(posRight, shapeY)
  wallBottom = love.physics.newFixture(posBottom, shapeX)
  wallRight:setRestitution(1.0)
  wallLeft:setRestitution(1.0)
  wallTop:setRestitution(1.0)
  wallBottom:setSensor(true)
  -- bounds shape
  shapeXY = love.physics.newRectangleShape(BOUNDS_WIDTH, BOUNDS_HEIGHT)
  posCenter = love.physics.newBody(world, 0, 0, "static")
  wallBounds = love.physics.newFixture(posCenter, shapeXY)
  wallBounds:setSensor(true)
  -- paddle
  shapeP = love.physics.newRectangleShape(10, 2)
  posP = love.physics.newBody(world, 0, 0, "dynamic")
  paddle = love.physics.newFixture(posP, shapeP)
  mouse = love.physics.newMouseJoint(posP, 0,0)
  -- posP:setFixedRotation(true)
  posP:setAngularDamping(100)
  paddle:setRestitution(1.5)
  -- ball
  shapeBall = love.physics.newCircleShape(1)
  posBall = love.physics.newBody(world, 0, 0, "dynamic")
  ball = love.physics.newFixture(posBall, shapeBall)
  ball:setRestitution(0.5)
  posBall:setBullet(true)
end

function game:enter(previous)
  reset()
end

function game:leave()
  
end

local breakSound = love.audio.newSource("assets/audio/270310__littlerobotsoundfactory__explosion-04.wav", "static")
local bonusSound = love.audio.newSource("assets/audio/270325__littlerobotsoundfactory__hit-02.wav", "static")
local paddleSound = love.audio.newSource("assets/audio/270315__littlerobotsoundfactory__menu-navigate-03.wav", "static")

local FUSE = 3.0 -- seconds

local function breakContacting(body)
  local success = false
  for i, contact in ipairs(body:getContacts()) do 
    if contact:isTouching() then
      for i, f in ipairs({contact:getFixtures()}) do
        if f:getUserData() == "brick" then
          f:getBody():setType("dynamic")
          f:setUserData(FUSE) -- prime fuse
          breaks = breaks + 1
          success = true
        end
      end
    end
  end
  return success
end

local lastTouch = true

function game:update(dt)
  if love.keyboard.isDown("r") then
    reset()
  elseif won() then
    return
  end
  time = time + dt
  world:update(dt)
  posP:applyTorque(-800 * math.pow(posP:getAngle(), 3))
  mouse:setTarget(camera:mousePosition())


  if breakContacting(posBall) then
    love.audio.setPosition(-posBall:getX()/BOUNDS_WIDTH, 0, 0)
    love.audio.play(breakSound)
  end

  for i, brick in ipairs(bricks) do
    if brick:getBody():getType() == "dynamic" then
      local fuse = brick:getUserData()
      if fuse then
        if fuse <= 0.0 then
          if breakContacting(brick:getBody()) then
            love.audio.setPosition(-brick:getBody():getX()/BOUNDS_WIDTH, 0, 0)
            love.audio.play(bonusSound)
          end
          brick:setUserData(nil)
        else
          brick:setUserData(fuse - dt)
        end
      end
    end
  end

  if posBall:isTouching(posP)then
    if lastTouch then
      love.audio.setPosition(-posP:getX()/BOUNDS_WIDTH, 0, 0)
      love.audio.play(paddleSound)
    end
    lastTouch = false
  else
    lastTouch = true
  end

  if not wallBounds:getBody():isTouching(posBall) then
    posBall:setPosition(0, 0)
    posBall:setLinearVelocity(0, 0)
    drops = drops + 1
  end
  if not wallBounds:getBody():isTouching(posP) then
    posP:setPosition(0, 0)
  end
end

function game:wheelmoved(x,y)
  posP:applyTorque(-800 * y)
end

local function renderShape(t, fixture) 
  local shape = fixture:getShape()
  local body = fixture:getBody()
  love.graphics.polygon(t, body:getWorldPoints(shape:getPoints()))
end


local red = {1.0, 0.5, 0.5} 
local blue = {0.5, 0.5, 1.0}
local green = {0.5, 1.0, 0.5}
local white = {1.0, 1.0, 1.0}

local fuseEffect = tween.new(FUSE, red, white)

function game:draw(dt)
  -- objects
  camera:attach()
  love.graphics.setColor(white)
  renderShape("fill", paddle)
  renderShape("line", paddle)
  renderShape("line", wallBounds)
  love.graphics.circle("fill", posBall:getX(), posBall:getY(), shapeBall:getRadius())
  for i, v in ipairs(bricks) do
    if v:getBody():getType() == "dynamic" then
      fuseEffect:set(FUSE - (v:getUserData() or 0))
    else 
      fuseEffect:set(0)
    end
    love.graphics.setColor(red)
    renderShape("fill", v)
  end
  camera:detach()
  -- text
  love.graphics.setColor(white, 0.7)
  love.graphics.printf(time, 0, 0, love.graphics.getWidth(), "left")
  love.graphics.printf(drops .. " drops", 0, 0, love.graphics.getWidth(), "right")
  if won() then
    love.graphics.setColor(green, 0.7)
    love.graphics.printf("GREAT\nSUCCESS", 0, love.graphics.getHeight()/4, love.graphics.getWidth()/2, "center", 0, 2)
    love.graphics.printf("(press 'R')", 0, love.graphics.getHeight()/2, love.graphics.getWidth(), "center")
  end
end

return game