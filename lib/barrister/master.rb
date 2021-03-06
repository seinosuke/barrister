module Barrister
  class Master
    include Barrister::Action
    using Barrister::Extension

    attr_accessor :logger
    attr_reader :action_plan, :field

    EVASIVE_PATTERN = {
      :normal => 0,
      :on_side1 => 1,
      :on_side2 => 2,
    }

    MOVE_VOICES = [
      "tsurai01.wav",
      "tsurai02.wav",
      "tsurai03.wav",
      "tsurai04.wav",
      "kaeritai.wav",
      "dame.wav",
    ]

    PYLON_VOICES = [
      "pylon01.wav",
      "pylon02.wav",
      "pylon03.wav",
    ]

    def initialize
      load_config
      setup_logger
      @logger.each_value { |log| log.info("Launch Barrister...") }
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
      @debug = Barrister.options[:debug]
      @threshold = Barrister.options[:threshold]
      @goal = Barrister.options[:goal]
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

      unless @debug
        @slaves.each do |_, slave|
          unless slave.alive?
            raise Barrister::I2cError, Error::MESSAGES[:invalid_i2c_responce]
          end
        end
      end
      @logger.each_value { |log| log.info("All I2C connections are successful!") }
    end

    # Make an action plan from `@config[:ActionPlan]`.
    def make_plan(original = nil)
      from = Marshal.load(Marshal.dump(@position))
      present_angle = @angle
      @action_plan =[]
      original ||= @config[:ActionPlan]

      original.map do |action|
        {:to => action[0], :pylon => action[1]}
      end.map do |action|
        target_angle = dir_to_angle((Vector[*action[:to]] - Vector[*from]).to_a)
        turning_plan(target_angle - present_angle)
        present_angle = target_angle
        from = action[:to]
        @action_plan << {:method => :move, :param => true}

        if action[:pylon]
          target_angle = dir_to_angle((Vector[*action[:pylon]] - Vector[*from]).to_a)
          turning_plan(target_angle - present_angle)
          present_angle = target_angle
          @action_plan << {:method => :collect_pylon, :param => action[:pylon]}
        end
      end
    end

    def detect_object
      distance = get_distance
      distance = get_distance
      sleep 1
      distance = get_distance
      next_pos = (Vector[*@position] + Vector[*angle_to_dir]).to_a
      p distance
      # @field.nodes[next_pos[0]][next_pos[1]] = case distance
      next_pos.tap do |x, y|
        @field.nodes[x][y] = case distance
        when ->(d) { d[0] < 20 && d[1] > 10 }
          # puts "パイロン"
          Field::NODE_TYPE[:pylon]
        when ->(d) { d[0] < 15 && d[1] < 15 }
          # puts "箱"
          Field::NODE_TYPE[:box]
        else
          Field::NODE_TYPE[:normal]
        end
      end
      next_pos
    end

    def search
      # unknown_pylons = [[9, 10], [10, 8], [6, 6], [5, 11], [10, 11], [7, 9], [8, 9], [0, 8], [5, 9]]
      # unknown_boxes = [[9, 11], [10, 9], [8, 6], [7, 8], [6, 11], [5, 6], [3, 11], [3, 7], [2, 9], [0, 7], [0, 11]]
      # unknown_pylons.each do |x, y|
      #   @field.set_object(x, y, :pylon)
      # end
      # unknown_boxes.each do |x, y|
      #   @field.set_object(x, y, :box)
      # end

      plan = []
      loop do
        # next_pos = (Vector[*@position] + Vector[*angle_to_dir]).to_a
        next_pos = detect_object
        break if @position == @goal
        if @angle == 0 && next_pos == @goal
          break if next_pos.tap { |x, y| break @field.nodes[x][y] == Field::NODE_TYPE[:box] }
        end

        if next_pos[1] > 11 || next_pos[1] < 6
          plan = uturn_actions
        else
          case next_pos.tap { |x, y| break @field.nodes[x][y] }
          when Field::NODE_TYPE[:normal], Field::NODE_TYPE[:storage_space]
            plan.push({:method=>:move, :param=>true})
          when Field::NODE_TYPE[:pylon]
            plan.push({:method=>:collect_pylon, :param=>next_pos})
          when Field::NODE_TYPE[:box]
            if (@position[1] == 10 && @angle == 0) || (@position[1] == 7 && @angle == 180)
              plan.push(*evasive_actions(EVASIVE_PATTERN[:on_side2]))
            else
              plan.push(*evasive_actions(EVASIVE_PATTERN[:normal]))
            end
          end
        end

        carry_out_for_unknownarea(plan)
      end
      print_flush
    rescue Interrupt
      stop
      puts self
      exit 0
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

    def will_be_back
      options = {
        :x_size => @field.x_size,
        :y_size => @field.y_size,
        :start => @position,
        :goal => [9, 6],
        :blocks => @field.boxes,
      }
      a_star = AStar.new(options)
      a_star.start
      make_plan(a_star.route.reverse.map { |pos| [pos, false] })
      carry_out @action_plan
    end

    def carry_out(plan)
      loop do
        print_flush
        action = plan.shift
        break unless action
        take action
      end
    rescue Interrupt
      st_off
      dc_stop
      stop
      exit 0
    end

    def take(action)
      case action[:method]
      when :move
        thread = Thread.new do
          system "aplay #{Dir.home}/work/open_jtalk/#{MOVE_VOICES.sample}"
        end
        send(action[:method], *action[:param])
        sleep 0.8
        sleep 0.1 until on_cross?(@threshold)
        sleep 0.08
        stop; sleep 1
        thread.join
      when :turn
        send(action[:method], *action[:param])
        sleep 1.4
        stop; sleep 1
      when :collect_pylon
        thread = Thread.new do
          system "aplay #{Dir.home}/work/open_jtalk/#{PYLON_VOICES.sample}"
        end
        # move(false)
        # print_flush
        send(action[:method], *action[:param])
        # print_flush
        # move(true)
        thread.join

      when :release_pylons
        send(action[:method], *action[:param])
      end
    end

    private

    def carry_out_for_unknownarea(plan)
      loop do
        print_flush
        action = plan.shift
        break unless action
        # next_pos = (Vector[*@position] + Vector[*angle_to_dir]).to_a
        next_pos = detect_object
        unless @field.nodes[next_pos[0]].nil?
          case next_pos.tap { |x, y| break @field.nodes[x][y] }
          when Field::NODE_TYPE[:pylon]
            added_action = {:method=>:collect_pylon, :param=>next_pos}
            take added_action
            print_flush
          when Field::NODE_TYPE[:box]
            if @angle == 270 && action[:method] == :move
              added_plan = evasive_actions(EVASIVE_PATTERN[:on_side1])
              carry_out(added_plan)
              plan.unshift({:method=>:move, :param=>true})
              redo
            end
          end
        end
        take action
      end
    end

    def turning_plan(diff_angle)
      case diff_angle
      when 90, -270 then @action_plan << {:method => :turn, :param => true}
      when -90, 270 then @action_plan << {:method => :turn, :param => false}
      when 180, -180 then 2.times { @action_plan << {:method => :turn, :param => true} }
      end
    end

    def dir_to_angle(direction)
      case direction
      when [1, 0] then 90
      when [-1, 0] then 270
      when [0, 1] then 0
      when [0, -1] then 180
      end
    end

    def angle_to_dir
      case @angle
      when 0 then [0, 1]
      when 90 then [1, 0]
      when 180 then [0, -1]
      when 270 then [-1, 0]
      end
    end

    def evasive_actions(pattern = EVASIVE_PATTERN[:normal])
      case pattern
      when EVASIVE_PATTERN[:normal]
        right, left = case @angle
        when 0 then [1, -1]
        when 180 then [-1, 1]
        end
        right_pos = (Vector[*@position] + Vector[right, 0]).to_a
        if @field.nodes[right_pos[0]].nil?
          left_evasive_actions
        else
          right_evasive_actions
        end

      when EVASIVE_PATTERN[:on_side1]
        case @position[1]
        when 11
          [
            {:method=>:turn, :param=>false},
            {:method=>:move, :param=>true},
            {:method=>:turn, :param=>true},
          ]
        when 6
          [
            {:method=>:turn, :param=>true},
            {:method=>:move, :param=>true},
            {:method=>:turn, :param=>false},
          ]
        end
      when EVASIVE_PATTERN[:on_side2]
        case @position[1]
        when 10
          [
            {:method=>:turn, :param=>false},
            {:method=>:move, :param=>true},
            {:method=>:turn, :param=>true},
            {:method=>:turn, :param=>false},
            {:method=>:turn, :param=>false},
          ]
        when 7
          [
            {:method=>:turn, :param=>true},
            {:method=>:move, :param=>true},
            {:method=>:turn, :param=>false},
            {:method=>:turn, :param=>true},
            {:method=>:turn, :param=>true},
          ]
        end
      end
    end

    def right_evasive_actions
      [
        {:method=>:turn, :param=>true},
        {:method=>:move, :param=>true},
        {:method=>:turn, :param=>false},
        {:method=>:move, :param=>true},
        {:method=>:move, :param=>true},
        {:method=>:turn, :param=>false},
        {:method=>:move, :param=>true},
        {:method=>:turn, :param=>true},
      ]
    end

    def left_evasive_actions
      [
        {:method=>:turn, :param=>false},
        {:method=>:move, :param=>true},
        {:method=>:turn, :param=>true},
        {:method=>:move, :param=>true},
        {:method=>:move, :param=>true},
        {:method=>:turn, :param=>true},
        {:method=>:move, :param=>true},
        {:method=>:turn, :param=>false},
      ]
    end

    def uturn_actions
      case @angle
      when 0
        [
          {:method=>:turn, :param=>false},
          {:method=>:move, :param=>true},
          {:method=>:turn, :param=>false},
        ]
      when 180
        [
          {:method=>:turn, :param=>true},
          {:method=>:move, :param=>true},
          {:method=>:turn, :param=>true},
        ]
      end
    end
  end
end
