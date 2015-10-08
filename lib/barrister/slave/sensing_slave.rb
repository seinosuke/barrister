module Barrister::Slave
  class SensingSlave < BaseSlave

    # Get data of a distance from an object.
    def get_distance
      read(3, Barrister::COMMAND[:detector_mode])
    end

    # Return `true` if the machine was at a crossroads.
    def on_cross?(threshold)
      data = read(2, Barrister::COMMAND[:linetrace_mode])
      data[0] > threshold && data[1] > threshold
    end
  end
end
