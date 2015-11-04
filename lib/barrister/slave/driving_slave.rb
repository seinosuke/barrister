module Barrister::Slave
  class DrivingSlave < BaseSlave

    # A stepper motor is driven by the one-phase excitation system.
    # The motor rotates in the clockwise(CW) direction if `cw` is `true`,
    # other in the counterclockwise(CCW) direction.
    def rotate(cw = true)
      write(Barrister::COMMAND[cw ? :rotate_cw : :rotate_ccw])
    end

    # A stepper motor is driven by the 1-2-phase excitation system.
    def rotate12(cw = true)
      write(Barrister::COMMAND[cw ? :rotate12_cw : :rotate12_ccw])
    end

    # A motor rotates without P control.
    def turn(cw = true)
      write(Barrister::COMMAND[cw ? :turn_cw : :turn_ccw])
    end

    # Stop a stepper motor.
    def stop
      write(Barrister::COMMAND[:stop])
    end
  end
end
