require 'matrix'
require 'i2c'
require 'yaml'
require 'logger'

require "barrister/extension"
require "barrister/configuration"
require "barrister/error"
require "barrister/field"
require "barrister/master"
require "barrister/slave"
require "barrister/slave/base_slave"

module Barrister
  extend Configuration

  COMMAND = {
    :ping => 0xFF,

    :rotate_cw => 0x10,
    :rotate_ccw => 0x11,
    :stop => 0x12,
    :turn_cw => 0x13,
    :turn_ccw => 0x14,

    :detector_mode => 0x20,
    :linetrace_mode => 0x21,
  }

  # Alias for Barrister::Master.new
  def self.new
    Barrister::Master.new
  end
end
