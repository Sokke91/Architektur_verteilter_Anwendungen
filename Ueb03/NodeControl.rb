#!/usr/bin/ruby
# encoding: UTF-8
require 'socket'  
require 'json'

INIT_FILE = "/Users/jonasangel/Documents/HTW/Architektur_verteilter_Anwendungen/Ueb03/init.txt"
PORT = 5050
eingabe = '0'
LOCAL_FILE = "/Users/jonasangel/Documents/HTW/Architektur_verteilter_Anwendungen/Ueb03/local"

while eingabe != '3'
	puts "Auswahl "
	puts '1: Starte'
	puts "2: Neue Local File anlegen"
	puts "3: Programm beenden"
	eingabe = gets.chomp  #Lese eingabe 
	if eingabe == '1'   
		File.readlines(INIT_FILE).each do |line|
			node  = line.split(";") 
			msg = {:typ => "init"}
			s = UDPSocket.new
			s.send msg.to_json, 0, "localhost", node[2].to_i 
		end
	elsif eingabe == '2'
		File.delete(LOCAL_FILE) if File.exists?(LOCAL_FILE)
		f = File.new(LOCAL_FILE,"w")
		f.puts "0"
		f.close
	end		
end
		

