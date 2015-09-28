module Barrister::Slave
  class DrivingSlave < BaseSlave

    # A stepper motor is driven by a one-phase excitation system.
    # The motor rotates in the clockwise(CW) direction if `cw` is `true`,
    # other in the counterclockwise(CCW) direction.
    def rotate(cw = true)
      write(Barrister::COMMAND[cw ? :rotate_cw : :rotate_ccw])
    end

    # Stop a stepper motor.
    def stop
      write(Barrister::COMMAND[:stop])
    end
  end
end
