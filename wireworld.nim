type
  State* = enum
    ground, wire, head, tail

  World* = seq[State]

const WorldSize = 75

template get*[T](collection: openarray[T], x, y: int): T =
  collection[x + WorldSize * y]

proc newWorld*: World =
  newSeq(result, WorldSize * WorldSize)
  for idx in 0..< (WorldSize * WorldSize):
      result[idx] = ground

proc `$`*(world: World): string =
  result = ""
  for y in 0..<WorldSize:
    for x in 0..<WorldSize:
      case world.get(x, y):
        of ground: result.add(" ")
        of wire: result.add("-")
        of head: result.add("+")
        of tail: result.add("=")
    result.add("\n")

proc neighbors(world: World, x, y: int): array[State, int] =
  # Returns a array with the count of each state in the neighboring cells
  result[world.get(x, y)] -= 1
  for i in [x - 1, x, x + 1]:
    for j in [y - 1, y, y + 1]:
      if i >= 0 and i < WorldSize and j >= 0 and j < WorldSize:
        result[world.get(i, j)] += 1

proc newState(world: World, x, y: int): State =
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

proc process*(world: var World) =
  # Updates the entire world according to the automata rules.

  # We must copy world first though, otherwise we'll get incorrect updating
  var newworld = world
  for x in 0..<WorldSize:
    for y in 0..<WorldSize:
      # Update the new world 
      newworld.get(x, y) = world.newState(x, y)
  # Update the original with the new states
  world = newworld

if isMainModule:
  var world = newWorld()
  world.get(0, 0) = wire
  world.get(2, 0) = head
  world.get(0, 1) = wire
  world.get(0, 2) = tail
  world.get(1, 2) = head
  world.get(2, 2) = head

  for _ in 1..10:
    echo world
    world.process
  echo world
