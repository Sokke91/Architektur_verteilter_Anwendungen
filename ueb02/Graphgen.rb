#!/usr/bin/ruby 

# Ruby skript das einen zufälligen Zusammenhängenden Graphen 
# im Graphgviz Datei Format erstellt. 
# Aufruf:  ruby Graphgen.rb {Dateiname} {Anzahl Knoten} {Anzahl Kanten}
# Hinweis: Anzahl Kanten muss > anzahl Knoten sein.  


filename = ARGV[0]
n = ARGV[1].to_i
m = ARGV[2].to_i

if n.to_i > m.to_i 
  exit(0)
end

file = File.new("#{filename}.dot","w")

file.puts "graph G{"

x = 0
graphArr = []

i = 1
n.times do 
  i = i+1
  b = rand(i-1)+1
  b = b.to_i 
  if i > b
    graphArr.push "#{i}--#{b}"

  elsif i < b
    graphArr.push "#{b}--#{i}"
  end
end

while graphArr.length<m do
  a = rand(n-1)+1
  b = rand(n-1)+1
  if a > b 
    graphArr.push "#{a}--#{b}"
    graphArr.uniq!
  elsif a < b 
    graphArr.push "#{b}--#{a}"
    graphArr.uniq!
  end
end

graphArr.each do |g|
  file.puts"#{g}"
  puts"#{g}"
end
  
file.puts"}"
file.close