#!/usr/bin/ruby
# encoding: UTF-8
require 'socket'  
require 'json'

INIT_FILE = "/Users/jonasangel/Documents/HTW/Architektur_verteilter_Anwendungen/Ueb03/init.txt"
PORT = 5050
eingabe = '0'
socket = UDPSocket.new
socket.bind("localhost", PORT)

#Funktion zum Empfangen von UDP Nachrichten auf dem Socket
def receive_message(socket)
    begin 
      receive_msg = socket.recvfrom_nonblock(100) # Lese von Socket
      receive_msg = JSON.parse(receive_msg[0])
	  return receive_msg["send_msg_counter"].to_i, receive_msg["receive_msg_counter"].to_i 
    rescue IO::WaitReadable
      IO.select([socket])
      retry     
    end
  end

while eingabe != '5'
	puts "Auswahl "
	puts '1: Starte'
	puts "2: Einen Knoten beenden"
	puts "3: Alle Knoten beenden"
	puts "4: Prüfe Terminierung (Nur bei GameNode4)"
	puts '5: Programm beenden'

	eingabe = gets.chomp  #Lese eingabe 

	if eingabe == '1'   
		File.readlines(INIT_FILE).each do |line|
			node  = line.split(";") 
			msg = {:typ => "init"}
			s = UDPSocket.new
			s.send msg.to_json, 0, "localhost", node[2].to_i 
		end
	elsif eingabe == '2'
		puts 'Port:'
		id = gets.chomp.to_i
		msg = {:typ => 'control', :command => 'kill'}
		s = UDPSocket.new
		s.connect("localhost", id)
		s.send msg.to_json, 0
	elsif eingabe == '3'
		nodes_array = []
		File.readlines(INIT_FILE).each do |line|    #Gehe alle Nodes durch 
	      	node  = line.split(";")
			msg = {:typ => 'control', :command => 'kill_all'}
			s = UDPSocket.new
			s.send msg.to_json, 0 , "localhost", node[2].to_i
		end	
	elsif eingabe == '4'
		msg_send = []
		msg_receive = []
		2.times do |i|
			send = 0
			receive = 0
			File.readlines(INIT_FILE).each do |line|
				node  = line.split(";") 
				msg = {:typ => "control", :command => "get_counter",:source => PORT}
				s = UDPSocket.new
				s.send msg.to_json, 0, "localhost", node[2].to_i 
				buf_send, buf_receive = receive_message(socket)
				send += buf_send
				receive += buf_receive 
			end
			 msg_send[i] = send 
			 msg_receive[i] = receive
		end
		if (msg_send[0] == msg_send[1]) && (msg_receive[0] == msg_receive[1])
			puts "Spiel ist Terminiert"	
		else
			puts "Spiel läuft noch"
		end 
	end		
end
		

