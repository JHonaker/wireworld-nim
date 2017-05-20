import sdl2

type SDLException = object of Exception

type
  TileType = enum
    ground, wire, head, tail

  Input {.pure.} = enum none, reset, exit, groundmode, wiremode, headmode, tailmode, place

  Game = ref object
    inputs: array[Input, bool]
    mx, my: int
    renderer: RendererPtr

proc newGame(renderer: RendererPtr): Game =
  new result
  result.renderer = renderer

proc color(tile: TileType): Color =
  case tile:
    of ground:
      (r: 28'u8, g: 20'u8, b: 14'u8, a: 255'u8)
    of wire:
      (r: 234'u8, g: 225'u8, b: 93'u8, a: 255'u8)
    of head:
      (r: 43'u8, g: 145'u8, b: 255'u8, a: 255'u8)
    of tail:
      (r: 255'u8, g: 57'u8, b: 43'u8, a: 255'u8)

proc keyToInput(key: Scancode): Input =
  case key:
    of SDL_SCANCODE_Q: Input.exit
    of SDL_SCANCODE_A: Input.groundmode
    of SDL_SCANCODE_S: Input.wiremode
    of SDL_SCANCODE_D: Input.headmode
    of SDL_SCANCODE_F: Input.tailmode
    of SDL_SCANCODE_R: Input.reset
    else: Input.none

proc handleInput(game: Game) =
  var event = defaultEvent
  while pollEvent(event):
    case event.kind:
      of QuitEvent:
        game.inputs[Input.exit] = true
      of KeyDown:
        game.inputs[event.key.keysym.scancode.keyToInput] = true
      of KeyUp:
        game.inputs[event.key.keysym.scancode.keyToInput] = false
      of MouseMotion:
        game.mx = event.motion.x
        game.my = event.motion.y
      of MouseButtonDown:
        if event.button.button == BUTTON_LMASK:
          game.inputs[Input.place] = true
      of MouseButtonUp:
        if event.button.button == BUTTON_LMASK:
          game.inputs[Input.place] = false
      else:
        discard


template sdlFailIf(cond: typed, reason: string) =
  if cond:
    raise SDLException.newException(reason & ", SDLError: " & $getError())

proc render(game: Game) =
  game.renderer.clear()
  game.renderer.present()

proc main =
  sdlFailIf(not sdl2.init(INIT_VIDEO or INIT_TIMER or INIT_EVENTS)):
    "SDL2 initialization failed."

  # Gets called at the end of the proc even if an exception has been thrown
  defer: sdl2.quit()

  sdlFailIf(not setHint("SDL_RENDER_SCALE_QUALTITY", "2")):
    "Linear texture filtering could not be enabled."

  let window = createWindow(title = "Wireworld",
                            x = SDL_WINDOWPOS_CENTERED,
                            y = SDL_WINDOWPOS_CENTERED,
                            w = 720, h = 720,
                                flags = SDL_WINDOW_SHOWN)

  sdlFailIf window.isNil: "Window could not be created."
  defer: window.destroy()

  let renderer = window.createRenderer(index = -1,
                                       flags = Renderer_Accelerated or Renderer_PresentVsync)

  sdlFailIf renderer.isNil: "Renderer could not be created."

  # Setting the default color
  renderer.setDrawColor(r = 28, g = 20, b = 14)

  var game = newGame(renderer)
  # Game Loop
  while not game.inputs[Input.exit]:
    game.handleInput()
    game.render()

if isMainModule:
  main()
