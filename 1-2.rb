#!/usr/bin/env ruby

require 'pp'
require 'test/unit/assertions'

def r i
  i.map { |l| l.split '' }
    .flatten
    .select { |c| '()'.include? c }
    .each_with_index
    .reduce(f: 0, b: []) do |memo, (c, index)|
      f = case c
          when '('
            memo[:f] + 1
          when ')'
            memo[:f] - 1
          end
      b = (f == -1) ? (memo[:b] << index + 1) : memo[:b]
      {f: f, b: b}
    end
end

[
  [%w{(())}, 0],
  [%w{()()}, 0],
  [%w{(((}, 3],
  [%w{(()(()(}, 3],
  [%w{))(((((}, 3],
  [%w{())}, -1],
  [%w{))(}, -1],
  [%w{)))}, -3],
  [%w{)())())}, -3],
].each { |example, floor| raise Exception(example) unless r(example)[:f] == floor }

[
  [%w{)}, 1],
  [%w{()())}, 5],
].each { |example, position| raise Exception(example) unless r(example)[:b].first == position }

pp r $<
