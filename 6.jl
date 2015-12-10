using Base.Test

immutable Point
  x
  y
end

Base.sub(a, tl, br) = sub(a, tl.x:br.x, tl.y:br.y)

immutable Instruction{T}
  top_left
  bottom_right
end

@enum INSTRUCTIONS On Toggle Off

function parse_instruction(line)
  re = r"(turn on|toggle|turn off) (\d+),(\d+) through (\d+),(\d+)"
  actions = Dict(
    "turn on" => Instruction{On},
    "toggle" => Instruction{Toggle},
    "turn off" => Instruction{Off},
  )

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
@test parse_instruction("turn on 0,0 through 999,999") == Instruction{On}(Point(1, 1), Point(1000, 1000))
@test parse_instruction("toggle 0,0 through 999,0") == Instruction{Toggle}(Point(1, 1), Point(1000, 1))
@test parse_instruction("turn off 499,499 through 500,500") == Instruction{Off}(Point(500, 500), Point(501, 501))

process(i::Instruction{On}, v::Bool) = true
process(i::Instruction{Toggle}, v::Bool) = !v
process(i::Instruction{Off}, v::Bool) = false

process(i::Instruction{On}, v::Int) = v + 1
process(i::Instruction{Toggle}, v::Int) = v + 2
process(i::Instruction{Off}, v::Int) = max(0, v - 1)

function process(instruction, lights)
  map!(
    x -> process(instruction, x),
    sub(lights, instruction.top_left, instruction.bottom_right)
  )
end

lights_lit = falses(1000, 1000)
lights_brightness = zeros(Int, 1000, 1000)
for i in map(parse_instruction, eachline(STDIN))
  process(i, lights_lit)
  process(i, lights_brightness)
end

println(countnz(lights_lit))
println(sum(lights_brightness))
