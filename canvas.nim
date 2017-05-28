import dom, jsconsole, times
import html5_canvas
import wireworld

const
  TileSize = 10
  MinTicksPerSecond = 1
  MaxTicksPerSecond = 60
  WindowSize = WorldSize * TileSize
  BottomBarHeight = 1
  black = rgb(0, 0, 0)
  green = rgb(0, 255, 0)
  red = rgb(255, 0, 0)
  groundColor = rgb(28, 20, 14)
  wireColor = rgb(234, 225, 93)
  headColor = rgb(43, 145, 255)
  tailColor = rgb(255, 57, 43)

var TicksPerSecond = 10

proc clampSpeedChange(speed, delta: int): int =
  if speed + delta < 1:
    result = MinTicksPerSecond
  elif speed + delta > MaxTicksPerSecond:
    result = MaxTicksPerSecond
  else:
    result = speed + delta

type
  Input {.pure.} = enum
    none, reset,
    groundmode, wiremode, headmode, tailmode,
    place,
    pauseplay,
    speedup, speeddown

  DrawMode = enum
    GroundMode,
    WireMode,
    HeadMode,
    TailMode

  Game = ref object
    inputs: array[Input, bool]
    mx, my: int
    tx, ty: int
    canvas: Canvas
    context: CanvasRenderingContext2D
    world: World
    prevFrame: World
    drawmode: DrawMode
    paused: bool

  Rect* = tuple[x, y, w, h: float]

proc newGame(canvas: Canvas): Game =
  new result
  
  result.world = newWorld()
  result.prevFrame = newWorld(head)

  result.drawmode = WireMode
  result.paused = false
  result.canvas = canvas
  result.context = canvas.getContext2D()

proc color(tile: State): cstring =
  case tile:
    of ground: groundColor
    of wire: wireColor
    of head: headColor
    of tail: tailColor

proc fillRect(ctx: CanvasRenderingContext2D, rect: Rect) =
  ctx.fillRect(rect.x, rect.y, rect.w, rect.h)

proc strokeRect(ctx: CanvasRenderingContext2D, rect: Rect) =
  ctx.strokeRect(rect.x, rect.y, rect.w, rect.h)

proc screenToWorld(x, y: int): tuple[x, y: int] = (x div TileSize, y div TileSize)

proc keyToInput(key: int): Input =
  case key:
    of 65: Input.groundmode   #A
    of 83: Input.wiremode     #S
    of 68: Input.headmode     #D
    of 70: Input.tailmode     #F
    of 82: Input.reset        #R
    of 80: Input.pauseplay    #P
    of 38: Input.speedup      #up
    of 40: Input.speeddown    #down
    else: Input.none

proc processKeyUp(game: var Game, keyCode: int) =
  case keyCode.keyToInput:
    of Input.pauseplay:
      game.paused = not game.paused
    of Input.groundmode:
      game.drawmode = GroundMode
    of Input.wiremode:
      game.drawmode = WireMode
    of Input.headmode:
      game.drawmode = HeadMode
    of Input.tailmode:
      game.drawmode = TailMode
    of Input.reset:
      game = newGame(game.canvas)
    else: discard

proc processKeyDown(game: var Game, keyCode: int) =
  case keyCode.keyToInput:
    of Input.speedup:
      TicksPerSecond = TicksPerSecond.clampSpeedChange(1)
    of Input.speeddown:
      TicksPerSecond = TicksPerSecond.clampSpeedChange(-1)
    else: discard

proc drawState(game: Game): State =
  case game.drawmode:
    of GroundMode: ground
    of WireMode: wire
    of HeadMode: head
    of TailMode: tail

proc processClicks(game: var Game) =
  if game.inputs[Input.place]:
    game.world.get(game.tx, game.ty) = game.drawState

proc renderTile(game: Game, x, y: int) =
  let
    tileState = game.world.get(x, y)
    prevState = game.prevFrame.get(x,y)

  if tileState == prevState: return

  game.prevFrame.get(x,y) = tileState

  let
    tileColor = tileState.color
    tileRect: Rect = (float(x * TileSize), float(y * TileSize), float(TileSize), float(TileSize))

  # Draw the tile background
  game.context.fillStyle = tileColor
  game.context.fillRect(tileRect)
  # Draw the outline
  game.context.strokeStyle = black
  game.context.strokeRect(tileRect)

proc renderDrawMode(game: Game) =
  let
    x: float = 0
    y: float = WorldSize
    width = WorldSize / 2.0
    barRect: Rect = (
      x * TileSize, 
      y * TileSize, 
      width * TileSize, 
      float(BottomBarHeight * TileSize))

  game.context.fillStyle = game.drawState.color
  game.context.fillRect(barRect)

proc renderPauseState(game: Game) =
  let
    x = WorldSize / 2.0
    y: float = WorldSize
    width = WorldSize / 2.0
    color = case game.paused:
              of true: red
              of false: green
    barRect: Rect = (
      x * TileSize,
      y * TileSize,
      width * TileSize,
      float(BottomBarHeight * TileSize)
    )

  game.context.fillStyle = color
  game.context.fillRect(barRect)

proc renderBottomBar(game: Game) =
  game.renderDrawMode
  game.renderPauseState

proc renderWorld(game: Game) =
  for x in 0..<WorldSize:
    for y in 0..<WorldSize:
      game.renderTile(x, y)

proc render(game: Game) =
  
  game.renderWorld
  game.renderBottomBar

proc processWorld(game: Game) = game.world.process

# nim 0.17.0 or greater needed for requestAnimationFrame to be in the std lib, 
# otherwise uncomment the function bellow
# proc requestAnimationFrame(w: Window, function: proc (time: float)): int = 
#   {.emit: [result, "= window.requestAnimationFrame(", function, ");"] .}

proc performanceNow(): float =
  {.emit: [result, "= performance.now();"] .}

dom.window.onload = proc(e: dom.Event) =
  let canvas = dom.document.getElementById("canvas").Canvas
  canvas.width = WindowSize
  canvas.height = WindowSize + BottomBarHeight * TileSize

  var 
    game = newGame(canvas)
    startTime = performanceNow()
    lastTick = 0

  game.context.fillStyle = ground.color
  game.context.fillRect(0, 0, game.canvas.width.float, game.canvas.height.float)

  proc onMouseDown(event: Event) =
    game.inputs[Input.place] = true

  proc onMouseUp(event: Event) =
    game.inputs[Input.place] = false

  proc onMouseMove(event: Event) =
    let tile = screenToWorld(event.offsetX, event.offsetY)
    game.tx = tile.x
    game.ty = tile.y

  proc onKeyUp(event: Event) =
    game.processKeyUp(event.keyCode)

  proc onKeyDown(event: Event) =
    game.processKeyDown(event.keyCode)

  game.canvas.addEventListener("mousemove", onMouseMove)
  game.canvas.addEventListener("mousedown", onMouseDown)
  game.canvas.addEventListener("mouseup", onMouseUp)

  dom.window.addEventListener("keyup", onKeyUp)
  dom.window.addEventListener("keydown", onKeyDown)

  proc main(time: float) = 
    discard dom.window.requestAnimationFrame(main)
    game.render()
    game.processClicks()
    let newTick = int(float(TicksPerSecond) * (time - startTime) / 1000)
    if not game.paused:
      for tick in lastTick+1 .. newTick:
        game.processWorld()
    lastTick = newTick

  discard dom.window.requestAnimationFrame(main)
