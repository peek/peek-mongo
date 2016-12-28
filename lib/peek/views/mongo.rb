require 'mongo'
require 'concurrent'

# At the deepest of all commands in mongo go to Mongo::Socket
# and the following methods:
#
# - :read
# - :write

# Instrument Mongo time
class Mongo::Socket
  def read_with_timing(*args, &block)
    start = Time.now
    read_without_timing(*args, &block)
  ensure
    update_counters(start)
  end
  alias_method_chain :read, :timing

  def write_with_timing(*args, &block)
    start = Time.now
    write_without_timing(*args, &block)
  ensure
    update_counters(start)
  end
  alias_method_chain :write, :timing

  def update_counters(start)
    duration = (Time.now - start)

    Peek::Views::Mongo.command_time.update { |value| value + duration }
  end
end

# a better way to count all Mongo calls, is to look at the payload generation
module Mongo
  module Protocol
    class Query
      def payload_with_counter
        payload_without_counter
      ensure
        Peek::Views::Mongo.command_count.update { |value| value + 1 }
      end

      alias_method_chain :payload, :counter
    end

    class Insert
      def payload_with_counter
        payload_without_counter
      ensure
        Peek::Views::Mongo.command_count.update { |value| value + 1 }
      end

      alias_method_chain :payload, :counter
    end

    class Update
      def payload_with_counter
        payload_without_counter
      ensure
        Peek::Views::Mongo.command_count.update { |value| value + 1 }
      end

      alias_method_chain :payload, :counter
    end

    class GetMore
      def payload_with_counter
        payload_without_counter
      ensure
        Peek::Views::Mongo.command_count.update { |value| value + 1 }
      end

      alias_method_chain :payload, :counter
    end

    class Delete
      def payload_with_counter
        payload_without_counter
      ensure
        Peek::Views::Mongo.command_count.update { |value| value + 1 }
      end

      alias_method_chain :payload, :counter
    end
  end
end

module Peek
  module Views
    class Mongo < View
      class << self
        attr_accessor :command_time, :command_count
      end

      self.command_count = Concurrent::AtomicFixnum.new(0)
      self.command_time = Concurrent::AtomicFixnum.new(0)

      def formatted_duration
        ms = duration * 1000
        if ms >= 1000
          "%.2fms" % ms
        else
          "%.0fms" % ms
        end
      end

      def duration
        Peek::Views::Mongo.command_time.value
      end

      def calls
        Peek::Views::Mongo.command_count.value
      end

      def results
        { :duration => formatted_duration, :calls => calls }
      end

      private

      def setup_subscribers
        # Reset each counter when a new request starts
        before_request do
          Peek::Views::Mongo.command_time.value = 0
          Peek::Views::Mongo.command_count.value = 0
        end
      end
    end
  end
end
