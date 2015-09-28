module Barrister::Slave
  class SensingSlave < BaseSlave

    # Return `size` bytes of data from a sensing slave.
    def get_data(size)
      read(size)
    end
  end
end
