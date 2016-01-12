#!/usr/bin/ruby
# encoding: UTF-8
require 'socket'  
require 'json'

eingabe = '0'

while eingabe != '4'
	puts "Auswahl "
	puts '1: Initiator bestimmen und Gerücht verbreiten'
	puts "2: Einen Knoten beenden"
	puts "3: Alle Knoten beenden"
	puts '4: Programm beenden'

	eingabe = gets.chomp

	if eingabe == '1' 
		puts 'Port:'
		id = gets.chomp.to_i
		puts 'Gerücht:'
		val = gets.chomp
		msg = {:typ => 'control', :command => 'set_initiator', :value => val}
		s = UDPSocket.new
		s.connect("localhost", id)
		s.send msg.to_json, 0
	elsif eingabe == '2'
		puts 'Port:'
		id = gets.chomp.to_i
		msg = {:typ => 'control', :command => 'kill'}
		s = UDPSocket.new
		s.connect("localhost", id)
		s.send msg.to_json, 0
	elsif eingabe == '3'
		msg = {:typ => 'control', :command => 'kill_all'}
		s = UDPSocket.new
		s.connect("localhost", 5001)
		s.send msg.to_json, 0
	else
	end		
end
		

