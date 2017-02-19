require 'mongo'
require 'concurrent'

module Peek
  # Query times are logged by timing the Socket class of the Mongo Ruby Driver
  module MongoSocketInstrumented
    def read(*args, &block)
      start = Time.now
      super(*args, &block)
    ensure
      duration = (Time.now - start)
      ::Mongo::Socket.query_time.update { |value| value + duration }
    end

    def write(*args, &block)
      start = Time.now
      super(*args, &block)
    ensure
      duration = (Time.now - start)
      ::Mongo::Socket.query_time.update { |value| value + duration }
    end
  end

  # Query counts are logged to the Socket class by monitoring payload generation
  module MongoProtocolInstrumented
    def payload
      super
    ensure
      ::Mongo::Protocol::Message.query_count.update { |value| value + 1 }
    end
  end
end

# The Socket class will keep track of timing
# The MongoSocketInstrumented class overrides the read and write methods, rerporting the total count as the attribute :query_count
class Mongo::Socket
  prepend Peek::MongoSocketInstrumented
  class << self
    attr_accessor :query_time
  end
  self.query_time = Concurrent::AtomicFixnum.new(0)
end

# The Message class will keep track of count
# Nothing is overridden here, only an attribute for counting is added
class Mongo::Protocol::Message
  class << self
    attr_accessor :query_count
  end
  self.query_count = Concurrent::AtomicFixnum.new(0)
end

## Following classes all override the various Mongo command classes in Protocol to add counting
# The actual counting for each class is stored in Mongo::Protocol::Message

class Mongo::Protocol::Query
  prepend Peek::MongoProtocolInstrumented
end

class Mongo::Protocol::Insert
  prepend Peek::MongoProtocolInstrumented
end

class Mongo::Protocol::Update
  prepend Peek::MongoProtocolInstrumented
end

class Mongo::Protocol::GetMore
  prepend Peek::MongoProtocolInstrumented
end

class Mongo::Protocol::Delete
  prepend Peek::MongoProtocolInstrumented
end

module Peek
  module Views
    class Mongo < View
      def duration
        ::Mongo::Socket.query_time.value
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
        ::Mongo::Protocol::Message.query_count.value
      end

      def results
        { :duration => formatted_duration, :calls => calls }
      end

      private

      def setup_subscribers
        # Reset each counter when a new request starts
        subscribe 'start_processing.action_controller' do
          ::Mongo::Socket.query_time.value = 0
          ::Mongo::Protocol::Message.query_count.value = 0
        end
      end
    end
  end
end
