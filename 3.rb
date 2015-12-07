#!/usr/bin/env ruby

def direction x, y, dir
  case dir
  when '>' then x += 1
  when '<' then x -= 1
  when '^' then y += 1
  when 'v' then y -= 1
  else raise dir
  end

  [x, y]
end

def santa_vists dirs
  (x, y), counts = dirs.reduce([[0, 0], {[0, 0] => 1}]) do |((x, y), counts), dir|
      x, y = direction x, y, dir

      counts[[x, y]] ||= 0
      counts[[x, y]] += 1

      [[x, y], counts]
    end

    counts.keys
end

def answer lines
  dirs = lines.map { |l| l.split '' }.flatten

  lonely_santa = santa_vists(dirs).length

  a, b = dirs.partition.with_index { |_, index| (index % 2).zero? }
  aided_santa = (santa_vists(a) + santa_vists(b)).uniq.length

  [lonely_santa, aided_santa]
end

[
  ['>', [2, 2]],
  ['^v', [2, 3]],
  ['^>v<', [4, 3]],
  ['^v^v^v^v^v', [2, 11]],
].each { |example, number| raise example unless answer([example]) == number }

puts answer($<)
