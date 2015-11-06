module Barrister
  module Action
    #
    # Driving Slave
    #

    # The machine moves back and forward.
    def move(forward = true)
      unless @debug
        @slaves[:driving_right].rotate(forward)
        @slaves[:driving_left].rotate(forward)
      end

      @position = (Vector[*@position] + case @angle
        when 0 then Vector[0, forward ? 1 : -1]
        when 90 then Vector[forward ? 1 : -1, 0]
        when 180 then Vector[0, forward ? -1 : 1]
        when 270 then Vector[forward ? -1 : 1, 0]
      end).to_a
      @logger[:file].info("Action : move #{forward ? "forward" : "back"}")
    end

    # The machine moves back and forward.
    def move12(forward = true)
      unless @debug
        @slaves[:driving_right].rotate12(forward)
        @slaves[:driving_left].rotate12(forward)
      end

      @position = (Vector[*@position] + case @angle
        when 0 then Vector[0, forward ? 1 : -1]
        when 90 then Vector[forward ? 1 : -1, 0]
        when 180 then Vector[0, forward ? -1 : 1]
        when 270 then Vector[forward ? -1 : 1, 0]
      end).to_a
      @logger[:file].info("Action : move #{forward ? "forward" : "back"}")
    end

    # The machine turns on the spot.
    def turn(cw = true)
      unless @debug
        @slaves[:driving_right].turn(!cw)
        @slaves[:driving_left].turn(cw)
      end

      @angle += cw ? 90 : -90
      @angle = 0 if @angle == 360
      @angle = 270 if @angle == -90
      @logger[:file].info("Action : turn #{cw ? "cw" : "ccw"}")
    end

    def stop
      unless @debug
        @slaves[:driving_right].stop
        @slaves[:driving_left].stop
      end

      @logger[:file].info("Action : stop")
    end

    #
    # Sensing Slave
    #

    # Get data of a distance from an object.
    def get_distance
      @slaves[:sensing].get_distance
    end

    # Return `true` if the machine was at a crossroads.
    def on_cross?(threshold = 100)
      @slaves[:sensing].on_cross?(threshold)
    end

    #
    # Collecting Slave
    #

    def collect_pylon(x, y)
      unless @debug
        phase01; phase02; phase03; phase04
      end

      @field.remove_object(x, y)
      @logger[:file].info("Action : collect pylon")
    end

    def release_pylons
      unless @debug
        dc_rotate(false); sleep 0.5
        dc_stop; sleep 1
        dc_rotate(true); sleep 0.5
        dc_stop
      end

      @logger[:file].info("Action : release pylons")
    end

    # Move back.
    def phase01
      move(false); sleep 0.4
      stop; sleep 1
    end

    # Swing an arm to front and hold a pylon.
    def phase02
      st_rotate(true); sleep 0.2 # wait for rising
      st_stop; sleep 1
      swing_arm(true); sleep 2
      hold_pylon(false)
      st_rotate(false); sleep 1
      st_off; sleep 4 # wait for falling
      hold_pylon(true); sleep 1
    end

    # Let the pylon go.
    def phase03
      st_rotate(true); sleep 5.1 # wait for rising
      st_stop; sleep 1
      swing_arm(false); sleep 2
      st_off
      hold_pylon(false); sleep 1
    end

    # Return to a previous position.
    def phase04
      move(true)
      sleep 0.1 until on_cross?(@threshold)
      sleep 0.08
      stop
    end

    def st_rotate(cw = true)
      @slaves[:collecting].st_rotate(cw)
    end

    def st_stop
      @slaves[:collecting].st_stop
    end

    def st_off
      @slaves[:collecting].st_off
    end

    def swing_arm(front = true)
      @slaves[:collecting].swing_arm(front)
    end

    def hold_pylon(hold = true)
      @slaves[:collecting].hold_pylon(hold)
    end

    def dc_rotate(cw = true)
      @slaves[:collecting].dc_rotate(cw)
    end

    def dc_stop
      @slaves[:collecting].dc_stop
    end
  end
end
