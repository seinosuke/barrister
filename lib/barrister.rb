require 'i2c'
require 'yaml'

require "barrister/extension"
require "barrister/field"
require "barrister/master"
require "barrister/slave"
require "barrister/slave/base_slave"

module Barrister
  COMMAND = {
    :rotate_cw => 0x10,
    :rotate_ccw => 0x11,
    :stop => 0x12
  }
end
