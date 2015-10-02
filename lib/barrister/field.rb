module Barrister
  class Field
    NODE_TYPE = {
      :normal => 0,
      :pylon => 1,
      :box => 2,
      :barrister => 4
    }

    attr_accessor :nodes
    attr_reader :x_size, :y_size

    def initialize(config)
      @barrister = {}
      @x_size = config[:x_size]
      @y_size = config[:y_size]
      @nodes = Array.new(@x_size) do
        Array.new(@y_size) { NODE_TYPE[:normal] }
      end

      [:pylon, :box].each do |key|
        config[:known_area][key].each do |x, y|
          @nodes[x][y] = NODE_TYPE[key]
        end
      end
    end

    # Set the position and the angle of this machine.
    def update(position, angle)
      @barrister[:position] = position
      @barrister[:angle] = angle
      @barrister[:position].tap do |x, y|
        @nodes[x][y] = NODE_TYPE[:barrister]
      end
    end

    # The specified object is set at (x, y).
    def set_object(x, y, type)
      @nodes[x][y] = NODE_TYPE[type]
    end

    # Remove an object at (x, y).
    # However, `:barrister` and `:box` are excluded.
    def remove_object(x, y)
      case @nodes[x][y]
      when NODE_TYPE[:box], NODE_TYPE[:barrister]
      else @nodes[x][y] = NODE_TYPE[:normal]
      end
    end

    # Returns a string of a game field in human-readable form.
    def to_s
      @y_size.times.to_a.reverse.map do |y|
        to_s_helper(y, true) <<
        "\n#{" "*4}" << @x_size.times.to_a.map do |x|
          case @nodes[x][y]
          when NODE_TYPE[:barrister]
            case @barrister[:angle]
            when 90 then "  \e[46m  \e[0m\e[44m  \e[0m"
            when 270 then "\e[44m  \e[0m\e[46m  \e[0m  "
            else "  \e[46m  \e[0m  "
            end
          when NODE_TYPE[:normal] then " " * 6
          when NODE_TYPE[:pylon] then "  \e[41m  \e[0m  "
          when NODE_TYPE[:box] then "\e[43m#{" "*6}\e[0m"
          end
        end.join <<
        to_s_helper(y, false)
      end.join
    end

    private

    def to_s_helper(y, up)
      "\n#{" "*4}" << @x_size.times.to_a.map do |x|
        case @nodes[x][y]
        when NODE_TYPE[:barrister]
          if (@barrister[:angle] == 0 && up) || (@barrister[:angle] == 180 && !up)
            "\e[46m  \e[0m\e[44m  \e[0m\e[46m  \e[0m"
          else "\e[46m  \e[0m  \e[46m  \e[0m"
          end
        when NODE_TYPE[:box] then "\e[43m#{" "*6}\e[0m"
        else "\e[47m  \e[0m  \e[47m  \e[0m"
        end
      end.join
    end
  end
end
