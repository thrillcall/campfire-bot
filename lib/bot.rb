# External Libs
require 'rubygems'
require 'active_support'
require 'yaml'
require 'eventmachine'

# Local Libs
require "#{BOT_ROOT}/lib/message"
require "#{BOT_ROOT}/lib/event"
require "#{BOT_ROOT}/lib/plugin"

# requires http://github.com/joshwand/tinder to fix broken listen support
gem 'tinder', '>= 1.3.1'; require 'tinder'

module CampfireBot
  class Bot
    # this is necessary so the room and campfire objects can be accessed by plugins.
    include Singleton

    # FIXME - these will be invalid if disconnected. handle this.
    attr_reader :campfire, :rooms, :config

    def initialize
      if BOT_ENVIRONMENT.nil?
        puts "you must specify a BOT_ENVIRONMENT"
        exit 1
      end
      @timeouts = 0
      @config   = YAML::load(File.read("#{BOT_ROOT}/config.yml"))[BOT_ENVIRONMENT]
      @rooms    = {}
    end

    def connect
      load_plugins unless !@config['enable_plugins']
      begin
        join_rooms
      rescue Errno::ENETUNREACH, SocketError => e
        abort "We had trouble connecting to the network: #{e.class}: #{e.message}"
      rescue Exception => e
        abort "Unhandled exception while joining rooms: #{e.class}: #{e.message}"
      end  
    end

    def run(interval = 5)
      catch(:stop_listening) do
        trap('INT') { throw :stop_listening }
        
        # since room#listen blocks, stick it in its own thread
        @rooms.each_pair do |room_name, room|
          Thread.new do
            begin
              room.listen do |raw_msg|
                handle_message(CampfireBot::Message.new(raw_msg.merge({:room => room})))
              end
            rescue Exception => e 
              trace = e.backtrace.join("\n")
              puts "something went wrong! #{e.message}\n #{trace}"
            end
          end
        end

        loop do
          begin
            @rooms.each_pair do |room_name, room|

              # I assume if we reach here, all the network-related activity has occured successfully
              # and that we're outside of the retry-cycle
              @timeouts = 0

              # Here's how I want it to look
              # @room.listen.each { |m| EventHandler.handle_message(m) }
              # EventHanlder.handle_time(optional_arg = Time.now)

              # Run time-oriented events
              Plugin.registered_intervals.each  do |handler| 
                begin
                  handler.run(CampfireBot::Message.new(:room => room))
                rescue
                  puts "error running #{handler.inspect}: #{$!.class}: #{$!.message}",
                    $!.backtrace
                end
              end

              Plugin.registered_times.each_with_index  do |handler, index| 
                begin
                  Plugin.registered_times.delete_at(index) if handler.run
                rescue
                  puts "error running #{handler.inspect}: #{$!.class}: #{$!.message}",
                    $!.backtrace
                end
              end

            end
            STDOUT.flush
            sleep interval
          rescue Timeout::Error => e
            if @timeouts < 5
              sleep(5 * @timeouts)
              @timeouts += 1
              retry
            else
              raise e.message
            end
          end
        end
      end
    end

    private

    def join_rooms
      join_rooms_as_user
      puts "#{Time.now} | #{BOT_ENVIRONMENT} | Loader | Ready."
    end
    
    def join_rooms_as_user
      @campfire = Tinder::Campfire.new(@config['site'], :ssl => @config['use_ssl'], :username => @config['api_key'], :password => 'x')

      @config['rooms'].each do |room_name|
        @rooms[room_name] = @campfire.find_room_by_name(room_name)
        res = @rooms[room_name].join
        raise Exception.new("got #{res.code} error when joining room #{room_name}: #{res.body}") if res.code != 200 
      end
    end

    def load_plugins
      @config['enable_plugins'].each do |plugin_name|
        load "#{BOT_ROOT}/plugins/#{plugin_name}.rb"
      end

      # And instantiate them
      Plugin.registered_plugins.each_pair do |name, klass|
        puts "#{Time.now} | #{BOT_ENVIRONMENT} | Loader | loading plugin: #{name}"
        STDOUT.flush
        Plugin.registered_plugins[name] = klass.new
      end
    end

    def handle_message(message)
      # puts message.inspect

      if message['body'].nil?
        puts "handling nil messsage 1 '#{message}'"
        return
      end

      # only process non-bot messages
      unless @config['fullname'] == message[:person]
        puts "#{Time.now} | #{message[:room].name} | #{message[:person]} | #{message[:message]}"
        
        %w(commands speakers messages).each do |type|
          Plugin.send("registered_#{type}").each do |handler|
            begin
              handler.run(message)
            rescue
              puts "error running #{handler.inspect}: #{$!.class}: #{$!.message}",
                $!.backtrace
            end
          end
        end
        
      end

      
    end

  end
end

def bot
  CampfireBot::Bot.instance
end
