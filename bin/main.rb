$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'barrister'
require 'pp'
require 'pry'

config_file = File.expand_path('../../bin/config.yml', __FILE__)
log_file = File.expand_path('../../log/test.log', __FILE__)

Barrister.configure do |config|
  config.debug = true
  config.config_file = config_file
  config.log_file = log_file
  config.threshold = 140
  config.goal = [0, 11]
end
barrister = Barrister.new

action_plan = barrister.action_plan

action_plan.push(*[
  {:method=>:release_pylons, :param=>nil},
  {:method=>:turn, :param=>true},
  {:method=>:move, :param=>true},
  {:method=>:turn, :param=>false},
  {:method=>:move, :param=>true},
])

barrister.carry_out action_plan

barrister.search
barrister.will_be_back

puts barrister
