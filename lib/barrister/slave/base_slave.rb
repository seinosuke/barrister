module Barrister::Slave
  class BaseSlave

    attr_reader :device, :address

    def initialize(device, address)
      @device = device
      @address = address
    end

    # Sends a byte data.
    def write(data)
      @device.write(@address, data)
    end

    # Tries to read `size` bytes.
    def read(size)
      data = @device.read(@address, size)
      data.bytes
    end
  end
end
