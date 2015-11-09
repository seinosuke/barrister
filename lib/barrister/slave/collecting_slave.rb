module Barrister::Slave
  class CollectingSlave < BaseSlave

    # A stepper motor is driven by a one-phase excitation system.
    def st_rotate(cw = true)
      write(Barrister::COMMAND[
        cw ? :st_rotate_cw : :st_rotate_ccw])
    end

    # Stop a stepper motor.
    def st_stop
      write(Barrister::COMMAND[:st_stop])
    end

    # The excitation of a stepper motor is turned off.
    def st_off
      write(Barrister::COMMAND[:st_off])
    end

    # Rotate a DC motor.
    def dc_rotate(cw = true)
      write(Barrister::COMMAND[
        cw ? :dc_rotate_cw : :dc_rotate_ccw])
    end

    # Stop a DC motor.
    def dc_stop
      write(Barrister::COMMAND[:dc_stop])
    end

    # Swing my arm to `front ? "front" : "back"`.
    def swing_arm(front = true)
      write(Barrister::COMMAND[
        front ? :swing_to_front : :swing_to_back])
    end

    # Hold a pylon if `hold` is `true`, if not let the pylon go.
    def hold_pylon(hold = true)
      write(Barrister::COMMAND[
        hold ? :hold : :let_go])
    end
  end
end
