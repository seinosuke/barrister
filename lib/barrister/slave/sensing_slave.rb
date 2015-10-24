module Barrister::Slave
  class SensingSlave < BaseSlave

    # Get data of a distance from an object.
    def get_distance
      data = read(4, Barrister::COMMAND[:detector_mode])
      data[1..3]
    end

    # Return `true` if the machine was at a crossroads.
    def on_cross?(threshold)
      # data1 = read(3, Barrister::COMMAND[:linetrace_mode])
      # sleep 0.01
      # data2 = read(3, Barrister::COMMAND[:linetrace_mode])
      # return false if data1[1] > 190 || data1[2] > 190
      # [data1, data2].all? do |data|
      #   data[1] > threshold || data[2] > threshold
      # end

      # data = read(3, Barrister::COMMAND[:linetrace_mode])
      # p data
      # return false if data[1] > 190 || data[2] > 190
      # data[1] > threshold || data[2] > threshold

      data = read(3, Barrister::COMMAND[:linetrace_mode])
      p data
      data[2] > threshold
    end

    def reach_top?
      data = read(3, Barrister::COMMAND[:collector_mode])
      data[1] == 0x01
    end
  end
end
