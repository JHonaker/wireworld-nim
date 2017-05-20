type
  State* = enum
    ground, wire, head, tail

  World*[N: static[int]] = array[N, array[N, State]]

proc `$`*[N](world: World[N]): string =
  result = ""
  for row in world:
    for col in row:
      case col:
        of ground: result.add(" ")
        of wire: result.add("-")
        of head: result.add("+")
        of tail: result.add("=")
    result.add("\n")

template get*[N](world: World[N], x, y: int): State =
  world[y][x]

proc neighbors[N](world: World[N], x, y: int): array[State, int] =
  # Returns a array with the count of each state in the neighboring cells
  result[world.get(x, y)] -= 1
  for i in [x - 1, x, x + 1]:
    for j in [y - 1, y, y + 1]:
      if i >= 0 and i < N and j >= 0 and j < N:
        result[world.get(i, j)] += 1

proc newState[N](world: World[N], x, y: int): State =
  # Returns the new state for the cell after its update
  #
  # The update algorithm is:
  #   Ground -> Ground
  #   Head -> Tail
  #   Tail -> Wire
  #   Wire -> Head if '1 or 2 neighbors are head' else Wire

  let
    current = world.get(x, y)
    neighbors = world.neighbors(x, y)
    headcount = neighbors[head]

  case current:
    of ground: result = ground
    of head: result = tail
    of tail: result = wire
    of wire:
      if headcount == 1 or headcount == 2:
        result = head
      else:
        result = wire

proc process*[N](world: var World[N]) =
  # Updates the entire world according to the automata rules.

  # We must copy world first though, otherwise we'll get incorrect updating
  var newworld = world
  for x in 0..<N:
    for y in 0..<N:
      # Update the new world 
      newworld.get(x, y) = world.newState(x, y)
  # Update the original with the new states
  world = newworld

if isMainModule:
  var world: World[3] = [[wire, ground, head],
                         [wire, ground, ground],
                         [tail, head, head]]

  for _ in 1..10:
    echo world
    world.process
  echo world
