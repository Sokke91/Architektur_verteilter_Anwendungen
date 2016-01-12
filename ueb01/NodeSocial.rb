#!/usr/bin/ruby 
# encoding: UTF-8

require 'socket'
require 'curses'
require  'json'
require 'logger'

Neighbour = Struct.new(:id,:name,:port) do
end  

#Konstanten
MAX_RUMOR = 3
INIT_FILE = "Documents/HTW/AVA/ueb01/init.txt"
GRAPH_FILE = "Documents/HTW/AVA/ueb01/Graph.dot"
LOGFILE =  "Documents/HTW/AVA/ueb01/node.log"


class Node
  
  public
  
  #Konstruktor 
  def initialize
    @logger = Logger.new(LOGFILE)

    @id = ARGV[0]
    @hostname = nil
    @port = nil 
    @neighbours = []
    @initiator = false
    
    @stop_sending = false
    @rumor_counter = 0
    
    @nodes_array = []
    @message =  {}

    read_init_file
    set_own_konfig
    choose_neighbours
  end
    
  #Ausgabe von Node id, hostname, port benachbarter Knoten
  def print_node
    puts "-----------------------------------------------------\n"
    puts "Node:#{@id} host:#{@hostname} port:#{@port}"
    puts "Nachbar-Knoten:"
    @neighbours.each do |n|
       puts n.id
    end
    puts "-----------------------------------------------------\n"   
  end 
  
  #Erstellt neues Socket verbindung
  def open_port
    @socket = UDPSocket.new
    @socket.bind("localhost", @port.to_i)
  end
  
  # Funktion zum Empfangen einer Nachricht
  # Nachdem eine Nachricht Empfangen worden ist, wird geprüft ob es sich 
  # um eine Control oder Daten Nachricht handelt.
  def receive_message
    begin 
      receive_msg = @socket.recvfrom_nonblock(100) # Lese von Socket
      receive_msg = JSON.parse(receive_msg[0])
      if receive_msg['typ'] == 'control' 
        evaluate_control_msg(receive_msg)  # Überprüfe Kontroll Nachricht
      else
        @message = receive_msg  
        @rumor_counter = @rumor_counter + 1 
        puts "Nachricht erhalten von #{@message["source"]} :  Nachricht: #{@message["payload"]}"
        @logger.info "Node #{@id}: Nachricht erhalten von #{@message["source"]} :  Nachricht: #{@message["payload"]}"
        if @rumor_counter == MAX_RUMOR 
           puts "Okay, Ich glaube das Gerücht"
           @logger.info "Node #{@id}: Glaubt das Gerücht"
        end   
      end    
    rescue IO::WaitReadable
      IO.select([@socket])
      retry     
    end
  end  
  
  # Sende  empfangene Nachricht / Steuernachricht an alle Nachbarn. 
  def send_message_to_neighbours  
    unless @stop_sending  #Hat das Gerücht schon erhalten
      except_node = @message['source']  # Sende nicht mehr an den Knoten von dem er die Nachricht erhalten hat
      @message['source'] = @id
      @neighbours.each do |node|
        unless node.id == except_node  
          s= UDPSocket.new
          s.connect("localhost",node.port.to_i)
          s.send @message.to_json,0
          puts "Sende Nachricht an :  #{node.id}"
          @logger.info "Node #{@id}: Sende Nachricht an :  #{node.id}"
          @stop_sending = true
        end
      end 
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
  
  # Liest die Graphiz Datei aus und gibt die IDs der Nachbarn zurück
  def read_graphviz_file
    neighbours_id =[]
    File.readlines(GRAPH_FILE).each do |line|
      buf = line.split("-")
      z1 = buf[0]
      z2 = buf[2]
      if (z2.to_i==@id.to_i ||z1.to_i==@id.to_i)
        if z1 == @id
          neighbours_id << z2
        else 
          neighbours_id << z1
        end
      end         
    end
    neighbours_id  
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
  
  # Lese die Graphviz Datei aus und erstelle Nachbarn
  def choose_neighbours
    neighbours_ids = read_graphviz_file
    neighbours_ids.each do |id|
      node = @nodes_array[id.to_i-1]
      @neighbours << Neighbour.new(node[0],node[1],node[2])
    end  
  end

  # Lese die Kontroll Nachricht aus 
  def evaluate_control_msg(msg)
      if msg['command'] == 'set_initiator'
        @initiator = true
        puts "I am the initiator"
        @logger.info "Node #{@id}: ist jetzt Initiator"
        @message = {:typ => 'data', :payload => msg['value'] }
      elsif msg['command'] == 'kill'
        abort
      elsif msg['command'] == 'kill_all'
        @message = {:typ => 'control', :command => 'kill_all'}
        @stop_sending = false
        send_message_to_neighbours
        abort
      end        
  end 

end


###########################################Hauptprogramm##################################################
node = Node.new
node.print_node
node.open_port

while 1
  node.receive_message
  node.send_message_to_neighbours
  sleep(5)
end



