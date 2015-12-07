#!/usr/bin/env ruby

def sides lines
  lines.map { |l| l.split('x').map(&:to_i) }
end

def paper sides
  sides.map { |l, w, h| [l*w, w*h, h*l] }
       .map { |sides| sides.map { |a| 2*a }.reduce(&:+) + sides.min }
       .reduce(&:+)
end


def ribbon sides
  sides.map { |l, w, h| [[l+w, w+h, h+l], l*w*h] }
       .map { |sides, volume| 2*(sides.min) + volume }
       .reduce(&:+)
end

def answer lines
  sides = sides lines
  [paper(sides), ribbon(sides)]
end

[
  ['2x3x4', [58, 34]],
  ['1x1x10', [43, 14]],
].each { |example, total| raise example unless answer([example]) == total }

puts answer($<)
