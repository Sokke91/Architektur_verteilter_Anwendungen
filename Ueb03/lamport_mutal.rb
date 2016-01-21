#!/usr/bin/ruby 
# encoding: UTF-8

require 'socket'
require 'curses'
require  'json'
require 'logger'

Neighbour = Struct.new(:id,:name,:port) do
end  

INIT_FILE = "/Users/jonasangel/Documents/HTW/AVA/ueb03/init.txt"
LOCALHOST_FILE = "/Users/jonasangel/Documents/HTW/AVA/ueb03/localhost.txt"

class Node
  
  public
  
  #Konstruktor 
  def initialize
    @id = ARGV[0]
    @hostname = nil
    @port = nil 
    @neighbours = []
    @nodes_array = []
    @request_array = []
    @ack_counter = 0
    @timestamp = 0
    read_init_file
    set_own_konfig
    choose_neighbours
  end

  #Ausgabe von Node id, hostname, port benachbarter Knoten
  def print_node
    puts "-----------------------------------------------------\n"
    puts "Node:#{@id} Host:#{@hostname} Port:#{@port} Typ:#{@node_type} "
    puts "-----------------------------------------------------\n"   
  end

  #Erstellt neues Socket verbindung
  def open_port
    @socket = UDPSocket.new
    @socket.bind("localhost", @port.to_i)
  end

  def receive_message
    begin 
      receive_msg = @socket.recvfrom_nonblock(100) # Lese von Socket
      @timestamp+=1 
      Thread.new(receive_msg){
        receive_msg = JSON.parse(receive_msg[0])
        if receive_msg["typ"] == "release"
        	
        elsif receive_msg["typ"] == "request"
	      	@request << [receive_msg["timestamp"].to_i, receive_msg["id"].to_i]
	      	@request.sort!
	      	send_ack(receive_msg["source"].to_i)
	     elsif receive_msg["typ"] == "ack"
	      	@ack_counter+= 1		 	
	    end
	    if ack_counter == @neighbours.size
	    	check_access
	    	@ack_counter = 0
	    	msg = {:typ => "request", :timestamp => @timestamp, :source => @port}
	    	send_message_to_neighbours
	    end	
      }
    rescue IO::WaitReadable
      IO.select([@socket])
      retry     
    end
  end  

 private

  # Lest die Konfig Datei ein 
  def read_init_file
    File.readlines(INIT_FILE).each do |line|
      node  = line.split(";")
      @nodes_array << node
    end
  end

  def check_access
  	if @request[0][1] == @id
  		puts "Ich darf bearbeiten"
  		#datei bearbeiten

  	else
  		puts "ich darf nicht bearbeiten"
  	end			
  end	

  # Sende  empfangene Nachricht / Steuernachricht an alle Nachbarn. 
  def send_request_msg  
	sleep(Random.rand(3))
	s= UDPSocket.new
	@neighbours.each do |node|
	  s.send msg.to_json, 0 , "localhost", node.port.to_i
	  puts "Sende Nachricht an :  #{node.id}"
	end 
  end

  # Sende  empfangene Nachricht / Steuernachricht an alle Nachbarn. 
  def send_release_msg 
	msg = {:typ => "release", :id => @id}
	s= UDPSocket.new
	@neighbours.each do |node|
	  s.send msg.to_json, 0 , "localhost", node.port.to_i
	  puts "Sende Nachricht an :  #{node.id}"
	end 
  end  

  def send_ack(source)
     s = UDPSocket.new
     msg = {:typ => "ack",:source => @port} 
     s.send msg.to_json, 0 , "localhost", source
     puts "Sende Bestätigung an #{source}"
  end  

  # Wählt aus dem Node Array die passenden Infos aus.
  def set_own_konfig
    @nodes_array.each do |node|
      if node[0] == @id
        @hostname = node[1]
        @port = node[2]
      end  
    end
  end

  # Waehlt die Nachbarknoten aus. 
  # Bei diesem Programm sind alle Knoten der Init File Nachbarn 
  def choose_neighbours
    @nodes_array.each do |node|
      unless node[0] == @id
        @neighbours << Neighbour.new(node[0],node[1],node[2]) 
      end  
    end 
  end



########################################### Hauptprogramm ##################################################
node = Node.new
node.print_node
node.open_port

while 1
	node.receive_message
end	

end  