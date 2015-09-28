module Barrister
  class Master
    using Barrister::Extension

    attr_reader :slaves

    def initialize
      load_config
      setup_slaves

      @field = Field.new(@config[:Field])
      @position = @config[:Barrister][:initial_position]
      @angle = @config[:Barrister][:initial_angle]

      # puts self
      # printf "\e[#{@field.y_size * 3 + 1}A"; STDOUT.flush; sleep 1
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
    end

    # Load a config file
    # and set these contents to `@config`.
    def load_config
      unless File.exist?(Barrister::CONFIG_FILE)
        raise IOError.new(Error::MESSAGES[:not_found])
      end

      @config = YAML.load_file(Barrister::CONFIG_FILE)
      @config.symbolize_keys!
    end

    def to_s
      @field.update(@position, @angle)
      @field.to_s
    end
  end
end
