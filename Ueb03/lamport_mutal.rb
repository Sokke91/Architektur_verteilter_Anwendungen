#!/usr/bin/ruby 
# encoding: UTF-8

require 'socket'
require 'curses'
require  'json'


Neighbour = Struct.new(:id,:name,:port) do
end  

INIT_FILE = "/Users/jonasangel/Documents/HTW/Architektur_verteilter_Anwendungen/Ueb03/init.txt"
LOCALHOST_FILE = "/Users/jonasangel/Documents/HTW/Architektur_verteilter_Anwendungen/Ueb03/local"
MAX_NULL = 3
MAX_COUNTER = 20

class Node
  
  public
  
  #Konstruktor 
  def initialize
    @id = ARGV[0]
    @hostname = nil
    @port = nil 
    @neighbours = []
    @nodes_array = []
    @request_queue = []
    @ack_counter = 0
    @timestamp = 0
    @null_counter = 0
    @want_enter_cs = false
    @finish = false
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
        Thread.current.abort_on_exception = true
        receive_msg = JSON.parse(receive_msg[0])
        if receive_msg["typ"] == "init"
          send_request_msg
        elsif receive_msg["typ"] == "release"
          @request_queue.delete_if {|request| (request[0] == receive_msg["timestamp"].to_i && request[1] == receive_msg["id"].to_i ) }
        elsif receive_msg["typ"] == "finish"
            @request_queue.delete_if {|request| request[1] == receive_msg["id"].to_i  }
        elsif receive_msg["typ"] == "request"
	      	@request_queue << [receive_msg["timestamp"].to_i, receive_msg["id"].to_i] 
          send_ack(receive_msg["source"].to_i)
	     elsif receive_msg["typ"] == "ack"
          @ack_counter+= 1
          if 	@ack_counter == @neighbours.size
              @want_enter_cs = true
          end  	 	
	     end
      }
    rescue IO::WaitReadable
      IO.select([@socket])
      retry     
    end
  end

  # Sende  empfangene Nachricht / Steuernachricht an alle Nachbarn. 
  def send_request_msg  
    sleep(Random.rand(2))
    @timestamp += 1
    timestamp_at_moment = @timestamp
    msg = {:typ => "request" , :timestamp => timestamp_at_moment , :id => @id.to_i , :source => @port}
    @request_message = msg
    @request_queue << [@request_message[:timestamp], @request_message[:id]]
    s= UDPSocket.new
    @neighbours.each do |node|
      s.send msg.to_json, 0 , "localhost", node.port.to_i
    end 
  end

  def want_enter_cs
    @want_enter_cs
  end

  def check_access
    @request_queue.sort! unless @request_queue.nil?     
    if (@request_queue[0][0] == @request_message[:timestamp] && @request_queue[0][1] == @id.to_i)
      @ack_counter = 0
      @want_enter_cs =false
      puts "Ich darf bearbeiten: Timestamp: #{@request_message[:timestamp]}"
      read_and_write_file
      @request_queue.delete_if {|request| (request[0] == @request_message[:timestamp] && request[1] == @id.to_i ) }
      send_release_msg
      send_request_msg
    else
      puts "Darf nicht bearbeiten"
    end     
  end   

  def finish?
    @finish
  end 

  def send_finish_msg
    msg = {:typ => "finish", :id => @id}
    s= UDPSocket.new
    @neighbours.each do |node|
      s.send msg.to_json, 0 , "localhost", node.port.to_i
      puts "Sende Finish Nachricht an :  #{node.id}"
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


  # Sende  empfangene Nachricht / Steuernachricht an alle Nachbarn. 
  def send_release_msg 
  	@timestamp += 1
    msg = {:typ => "release", :timestamp => @request_message[:timestamp] , :id => @id, :source => @port}
  	s= UDPSocket.new
  	@neighbours.each do |node|
  	  s.send msg.to_json, 0 , "localhost", node.port.to_i
  	end 
  end  

  def send_ack(source)
     @timestamp += 1
     s = UDPSocket.new
     msg = {:typ => "ack",:source => @port} 
     s.send msg.to_json, 0 , "localhost", source
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


  def read_and_write_file
    file_counter = ""
    file = File.open(LOCALHOST_FILE,"r+")
    file_counter = file.readline
    file_counter = file_counter.to_i
    if file_counter.abs >= MAX_COUNTER
      @finish = true
    end  
    puts "Node #{@id} counte = #{file_counter}"
    if @id.to_i % 2 == 0 
      file_counter -= 1
    else
      file_counter +=1 
    end
    if file_counter == 0 
       @null_counter += 1
       puts "0 gelesen"
       if @null_counter ==MAX_NULL
          @finish = true
       end 
    end
    file.seek(0,IO::SEEK_SET)
    file.puts file_counter
    file.seek(0,IO::SEEK_END)
    file.write "\n#{@id}"
    file.close    
  end  


########################################### Hauptprogramm ##################################################
node = Node.new
node.print_node
node.open_port
begin
Thread.new{
  Thread.current.abort_on_exception = true
  while node.finish? == false 
      if node.want_enter_cs
        node.check_access
      end 
  end
  node.send_finish_msg
  puts "Anhalten: 3 mal eine Null gelesen oder max. Zugriff erreicht."  
}

  while 1
	 node.receive_message
  end	
rescue Exception => msg
  puts msg
end  

end  