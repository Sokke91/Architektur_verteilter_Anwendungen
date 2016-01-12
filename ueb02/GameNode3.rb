#!/usr/bin/ruby 
# encoding: UTF-8

require 'socket'
require 'curses'
require  'json'
require 'logger'


Neighbour = Struct.new(:id,:name,:port) do
end  

#Konstanten

INIT_FILE = "/Users/jonasangel/Documents/HTW/AVA/ueb02/init.txt"
SEND_COUNTER = 3

class Node
  
  public
  
  #Konstruktor 
  def initialize
    @id = ARGV[0]
    @keep_percent = ARGV[1].to_i
    @accept_percent = ARGV[2].to_i
    @total_value = ARGV[3].to_i
    @weath = 0 
    @hostname = nil
    @port = nil 
    @neighbours = []
    @nodes_array = []
    @msg_queue = Queue.new
    @message =  {}
    read_init_file
    set_own_konfig
    choose_neighbours
  end
    
  #Ausgabe von Node id, hostname, port benachbarter Knoten
  def print_node
    puts "-----------------------------------------------------\n"
    puts "Node:#{@id} Host:#{@hostname} Port:#{@port} "
    puts "Spielbetrag: #{@total_value}"
    puts "Min akzeptables Angebot: #{@accept_percent} Prozent"
    puts "Biete anderen Knoten an: #{@keep_percent} Prozent"
    puts "Vermögen: #{@weath}"
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
      if receive_msg["typ"] == "control"
        evaluate_control_msg(receive_msg) 
      else    
        @msg_queue << receive_msg
      end       
    rescue IO::WaitReadable
      IO.select([@socket])
      retry     
    end
  end

  def evaluate_queue_msg
    receive_msg = @msg_queue.pop
    evaluate_data_message(receive_msg) # Werte Daten Nachricht aus  
  end  
  
  def is_empty
    @msg_queue.empty?
  end

  private
    
  # Lest die Konfig Datei ein 
  def read_init_file
    File.readlines(INIT_FILE).each do |line|
      node  = line.split(";")
      @nodes_array << node
    end
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

  # Lese die Kontroll Nachricht aus 
  def evaluate_control_msg(msg)
    if msg['command'] == 'set_initiator' 
      @initiator = true
      puts "I am the initiator"
      send_message_to_neighbours(generate_request_msg)
    elsif msg['command'] == 'kill'
      print_node
      abort
    elsif msg['command'] == 'kill_all'
      msg = {:typ => 'control', :command => 'kill_all'}
      print_node
      abort
    end        
  end

  # Sende  empfangene Nachricht / Steuernachricht an alle Nachbarn. 
  def send_message_to_neighbours(msg)  
   s= UDPSocket.new
   msg['source'] = @port
   SEND_COUNTER.times do  
      node = @neighbours[Random.rand(@neighbours.size)]
      s.send msg.to_json, 0 , "localhost", node.port.to_i
      puts "Sende Nachricht an :  #{node.id}"
   end 
  end

  # Wenn der Fallower das Angebot des Leaders akzeptiert, wird eine Acknowlegment 
  # Nachricht an den Leader gesendet. 
  def send_ack(source)
     s = UDPSocket.new
     msg = {:typ => "ack",:source => @port} 
     s.send msg.to_json, 0 , "localhost", source
     puts "Node #{@id}: Angebot Akzeptiert! Neues Vermögen: #{@weath}."
     puts "Sende Bestätigung an #{source}"
  end  

  def evaluate_data_message(msg)
      if msg["typ"] == "ack"
        @weath = @weath + ((@total_value.to_f / 100) * @keep_percent).to_i
        puts "Anfrage wurde Akzeptiert: Neues Vermögen: #{@weath}" 
      else  
        if accept_request(msg["value"].to_f,msg["total_value"].to_f)
          puts "Angebot akzeptiert!"
          @weath = @weath + msg["value"].to_i
          send_ack(msg["source"].to_i)
        else 
          puts "Angebot nicht akzeptiert"
        end
      end
      send_message_to_neighbours(generate_request_msg)      
  end

  def generate_request_msg
      keep = (@total_value.to_f / 100) * @keep_percent
      fallower_value = (@total_value - keep).to_i
      msg = {:typ => "request",:value => fallower_value,:total_value => fallower_value}
  end 

  def accept_request(val,total_val)
       accept = (total_val / 100) * @accept_percent
       val >= accept
  end

end


########################################### Hauptprogramm ##################################################
node = Node.new
node.print_node
node.open_port

begin
  Thread.new{
    Thread.current.abort_on_exception=true
   while 1
      node.evaluate_queue_msg unless node.is_empty 
    end   
  }
  while 1
    node.receive_message
  end 
rescue
  retry
end 



