module Barrister
  class Master
    using Barrister::Extension

    attr_reader :slaves

    def initialize
      puts "Launch Barrister..."
      load_config
      setup_slaves

      @field = Field.new(@config[:Field])
      @position = @config[:Barrister][:initial_position]
      @angle = @config[:Barrister][:initial_angle]
    end

    # Set up slave arduino chips.
    def setup_slaves
      @i2c_device = I2C.create(@config[:Barrister][:i2c_device]) rescue nil
      addresses = @config[:SlaveAddress]
      @slaves = {
        :driving_right => Slave::DrivingSlave.new(@i2c_device, addresses[:driving_right]),
        :driving_left => Slave::DrivingSlave.new(@i2c_device, addresses[:driving_left]),
        :sensing => Slave::SensingSlave.new(@i2c_device, addresses[:sensing]),
      }

      @slaves.each do |_, slave|
        unless slave.alive?
          raise Barrister::I2cError, Error::MESSAGES[:invalid_i2c_responce]
        end
      end
      puts "All I2C connections are successful!"
    end

    # Load a config file
    # and set these contents to `@config`.
    def load_config
      Barrister.set_defaults
      unless File.exist?(Barrister.options[:config_file])
        raise Errno::ENOENT, "A config file could not be found."
      end

      @config = YAML.load_file(Barrister.options[:config_file])
      @config.symbolize_keys!
    end

    # Return values from all sensors.
    def get_data
      data = @slaves[:sensing].get_data
      { :distance => data[1..3], :photo_ref => data[4..5] }
    end

    # The machine moves back and forward.
    def move(forward = true)
      @slaves[:driving_right].rotate(forward)
      @slaves[:driving_left].rotate(forward)
    end

    # The machine turns on the spot.
    def turn(cw = true)
      @slaves[:driving_right].turn(cw)
      @slaves[:driving_left].turn(!cw)
    end

    def stop
      @slaves[:driving_right].stop
      @slaves[:driving_left].stop
    end

    def to_s
      @field.update(@position, @angle)
      @field.to_s
    end

    def print_flush
      puts self
      printf "\e[#{@field.y_size * 3 + 1}A"; STDOUT.flush
      sleep 1
    end
  end
end
