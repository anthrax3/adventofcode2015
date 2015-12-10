using Base.Test

immutable Point
  x
  y
end

function turn_on(lights, top_left, bottom_right)
  lights[top_left.x:bottom_right.x, top_left.y:bottom_right.y] = true
  lights
end

function toggle(lights, top_left, bottom_right)
  a = sub(lights, top_left.x:bottom_right.x, top_left.y:bottom_right.y)
  for i in eachindex(a)
    a[i] = !a[i]
  end

  lights
end

function turn_off(lights, top_left, bottom_right)
  lights[top_left.x:bottom_right.x, top_left.y:bottom_right.y] = false
  lights
end

@test turn_on(falses(10, 10), Point(1, 1), Point(10, 10)) == trues(10, 10)
@test toggle([[true false]; [false true]], Point(1, 1), Point(2, 2)) == [
  [false true];
  [true false];
]
@test turn_off(trues(4, 4), Point(2, 2), Point(3, 3)) == [
  [true true true true];
  [true false false true];
  [true false false true];
  [true true true true];
]

immutable Instruction
  top_left
  bottom_right
end

immutable On
  instruction

  On(tl, br) = new(Instruction(tl, br))
end

immutable Toggle
  instruction

  Toggle(tl, br) = new(Instruction(tl, br))
end

immutable Off
  instruction

  Off(tl, br) = new(Instruction(tl, br))
end

function parse_instruction(line)
  re = r"(turn on|toggle|turn off) (\d+),(\d+) through (\d+),(\d+)"
  actions = Dict("turn on" => On, "toggle" => Toggle, "turn off" => Off)

  m = match(re, line)
  if m != nothing
    a, tl_x, tl_y, br_x, br_y = m.captures

    actions[a](
      Point(parse(Int, tl_x) + 1, parse(Int, tl_y) + 1),
      Point(parse(Int, br_x) + 1, parse(Int, br_y) + 1)
    )
  end
end

@test parse_instruction("invalid line") == nothing
@test parse_instruction("turn on 0,0 through 999,999") == On(Point(1, 1), Point(1000, 1000))
@test parse_instruction("toggle 0,0 through 999,0") == Toggle(Point(1, 1), Point(1000, 1))
@test parse_instruction("turn off 499,499 through 500,500") == Off(Point(500, 500), Point(501, 501))

dispatch_table = Dict(On => turn_on, Toggle => toggle, Off => turn_off)

lights = falses(1000, 1000)
for line in eachline(STDIN)
  i = parse_instruction(line)
  if i != nothing
    dispatch_table[typeof(i)](lights, i.instruction.top_left, i.instruction.bottom_right)
  end
end

println(countnz(lights))
