Camera = require "lib.camera"
Gamestate = require "lib.gamestate"
vector = require "lib.vector-light"
tiny = require "lib.tiny"
inspect = require "lib.inspect"
tween = require "lib.tween"

local game = require "gamestates/game"

mainFont = love.graphics.newFont("assets/NovaMono-Regular.ttf", 20) 
camera = Camera(0, 0)

ASPECT_RATIO = 16.0 / 9.0
BOUNDS_WIDTH = 64.0
BOUNDS_HEIGHT = BOUNDS_WIDTH * ASPECT_RATIO

function love.load()
  print(_VERSION)
  love.graphics.setFont(mainFont)
  love.resize(love.graphics.getWidth(), love.graphics.getHeight())
  Gamestate.registerEvents()
  Gamestate.switch(game)
end

function love.resize(w, h)
  if h / w < ASPECT_RATIO then
    camera:zoomTo( h / BOUNDS_HEIGHT )
  else
    camera:zoomTo(w / BOUNDS_WIDTH)
  end
end
