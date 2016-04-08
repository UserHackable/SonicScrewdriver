#!/usr/bin/env ruby

leds = 3

angle = 360.0 / leds

d = 6.0 / 10.0 
r = d / 2.0

puts d
puts r

puts "mark (#{r} #{r});"

puts "arc (p #{r} -15) (p #{r} #{180 - 15}) (p #{r} 15);"
puts "wire (p #{r} -15) (#{d} #{r - 0.07});"
puts "wire (p #{r} 15) (#{d} #{r + 0.07});"


leds.times do |i|
  a = angle * i
  led = "led#{i + 1}"
  puts "move #{led} (p #{0.16} #{a + 90});"
end
puts

leds.times do |i|
  a = angle * i
  led = "led#{i + 1}"
  puts "rotate =r#{a} '#{led}';"
end
puts

leds.times do |i|
  a = angle * i
  jp = "jp#{i + 1}"
  puts "move #{jp} (p 0.367 #{a});"
end
puts

puts "mark (#{r + d} #{r});"
leds.times do |i|
  a = angle * i
  jp = "jp#{i + 7}"
  puts "move #{jp} (p 0.367 #{a});"
end
puts

r = 3.0 / 16.0

4.times do |i|
  a = -30.0 * i + 45.0
  p = "p$#{i+1}"
  puts "move #{p} (p #{r} #{a});"
end
