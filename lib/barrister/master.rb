module Barrister
  class Master
    include Barrister::Action
    using Barrister::Extension

    attr_accessor :logger
    attr_reader :action_plan

    def initialize
      setup_logger
      @logger.each_value { |log| log.info("Launch Barrister...") }
      load_config
      setup_slaves

      @field = Field.new(@config[:Field])
      @position = @config[:Barrister][:initial_position]
      @angle = @config[:Barrister][:initial_angle]
      @field.barrister[:position] = Marshal.load(Marshal.dump(@position))
      make_plan
    end

    # Set up a logger variable.
    def setup_logger
      @logger = {
        :stdout => Logger.new(STDOUT),
        :file => Logger.new(Barrister.options[:log_file])
      }
      @logger.each_value do |log|
        log.datetime_format = "%Y-%m-%d %H:%M:%S "
      end
      Barrister::Error.logger = @logger
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

    # Set up slave arduino chips.
    def setup_slaves
      @i2c_device = I2C.create(@config[:Barrister][:i2c_device]) rescue nil
      addresses = @config[:SlaveAddress]
      @slaves = {
        :driving_right => Slave::DrivingSlave.new(@i2c_device, addresses[:driving_right]),
        :driving_left => Slave::DrivingSlave.new(@i2c_device, addresses[:driving_left]),
        :sensing => Slave::SensingSlave.new(@i2c_device, addresses[:sensing]),
        :collecting => Slave::CollectingSlave.new(@i2c_device, addresses[:collecting]),
      }

      @slaves.each do |_, slave|
        unless slave.alive?
          raise Barrister::I2cError, Error::MESSAGES[:invalid_i2c_responce]
        end
      end
      @logger.each_value { |log| log.info("All I2C connections are successful!") }
    end

    # Make an action plan from `@config[:ActionPlan]`.
    def make_plan
      from = Marshal.load(Marshal.dump(@position))
      present_angle = @angle
      @action_plan =[]

      @config[:ActionPlan].map do |action|
        {:to => action[0], :pylon => action[1]}
      end.map do |action|
        target_angle = dir_to_target((Vector[*action[:to]] - Vector[*from]).to_a)
        turning_plan(target_angle - present_angle)
        present_angle = target_angle
        from = action[:to]
        @action_plan << {:method => :move, :param => true}

        if action[:pylon]
          target_angle = dir_to_target((Vector[*action[:pylon]] - Vector[*from]).to_a)
          turning_plan(target_angle - present_angle)
          present_angle = target_angle
          @action_plan << {:method => :collect_pylon, :param => action[:pylon]}
        end
      end
    end

    def to_s
      @field.update(@position, @angle)
      @field.to_s
    end

    def print_flush
      puts self
      printf "\e[#{@field.y_size * 3 + 1}A"; STDOUT.flush
      sleep 0.2
    end

    private

    def turning_plan(diff_angle)
      case diff_angle
      when 90, -270 then @action_plan << {:method => :turn, :param => true}
      when -90, 270 then @action_plan << {:method => :turn, :param => false}
      when 180, -180 then 2.times { @action_plan << {:method => :turn, :param => true} }
      end
    end

    def dir_to_target(direction)
      case direction
      when [1, 0] then 90
      when [-1, 0] then 270
      when [0, 1] then 0
      when [0, -1] then 180
      end
    end
  end
end
