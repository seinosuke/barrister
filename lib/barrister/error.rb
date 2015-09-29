module Barrister
  class Error < StandardError
    MESSAGES = {
      :invalid_i2c_responce => <<-EOS.gsub(/^\s{2,}/, "")
        The I2C connection has been properly established,
        but a response to a living confirmation request signal
        from a master device is invalid.
      EOS
    }

    SLEEP_TIME = 0.5
    RETRY_UPTO = 3
    @cnt = 0

    class << self
      # Repeats retry in the range of the `RETRY_UPTO` times of retry
      # in `SLEEP_TIME`, a retry time interval.
      def count_retry(error, place)
        if (@cnt += 1) > RETRY_UPTO
          if block_given?
            yield
          else
            puts "Over a number of retry times."
            exit 1
          end
        end
        puts "#{error.class} is raised at #{place}."
        puts "This is the #{@cnt} times of retry."
        sleep SLEEP_TIME
      end

      # Resets a counter.
      def reset_retry
        @cnt = 0
      end
    end
  end

  # If an i2c operation fails, this error is raised.
  I2cError = Class.new(Error)
end
