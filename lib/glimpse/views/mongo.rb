require 'mongo'

# At the deepest of all commands in mongo go to Mongo::Connection
# and the following methods:
#
# - :send_message
# - :send_message_with_safe_check
# - :receive_message

# Instrument Mongo time
class Mongo::Connection
  class << self
    attr_accessor :command_time, :command_count
  end
  self.command_count = 0
  self.command_time = 0

  def send_message_with_timing(*args)
    start = Time.now
    send_message_without_timing(*args)
  ensure
    Mongo::Connection.command_time += (Time.now - start)
    Mongo::Connection.command_count += 1
  end
  alias_method_chain :send_message, :timing

  def send_message_with_safe_check_with_timing(*args)
    start = Time.now
    send_message_with_safe_check_without_timing(*args)
  ensure
    Mongo::Connection.command_time += (Time.now - start)
    Mongo::Connection.command_count += 1
  end
  alias_method_chain :send_message_with_safe_check, :timing

  def receive_message_with_timing(*args)
    start = Time.now
    receive_message_without_timing(*args)
  ensure
    Mongo::Connection.command_time += (Time.now - start)
    Mongo::Connection.command_count += 1
  end
  alias_method_chain :receive_message, :timing
end

module Glimpse
  module Views
    class Mongo < View
      def duration
        ::Mongo::Connection.command_time
      end

      def formatted_duration
        ms = duration * 1000
        if ms >= 1000
          "%.2fms" % ms
        else
          "%.0fms" % ms
        end
      end

      def calls
        ::Mongo::Connection.command_count
      end

      def results
        { :duration => formatted_duration, :calls => calls }
      end

      private

      def setup_subscribers
        # Reset each counter when a new request starts
        before_request do
          ::Mongo::Connection.command_time = 0
          ::Mongo::Connection.command_count = 0
        end
      end
    end
  end
end
