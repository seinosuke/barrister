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
    rescue Errno::EIO => e
      Barrister::Error.count_retry(e, caller[0])
      retry
    ensure
      Barrister::Error.reset_retry
    end

    # Tries to read `size` bytes.
    def read(size, *params)
      data = @device.read(@address, size, *params)
      data.bytes
    rescue Errno::EIO => e
      Barrister::Error.count_retry(e, caller[0])
      retry
    ensure
      Barrister::Error.reset_retry
    end

    # Transmit a living confirmation request signal
    # to a slave arduino chip.
    def alive?
      response = read(1, Barrister::COMMAND[:ping])
      response[0] == Barrister::COMMAND[:ping]
    end
  end
end
