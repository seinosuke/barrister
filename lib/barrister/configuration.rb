module Barrister
  module Configuration
    using Barrister::Extension

    OPTIONS_KEYS = [
      :config_file,
      :log_file,
      :display_mode,
    ].freeze

    DEFAULTS = {
      :config_file => File.expand_path('../../bin/config.yml', __FILE__),
      :log_file => File.expand_path('../../bin/barrister.log', __FILE__),
      :display_mode => :character,
    }.freeze

    attr_accessor *OPTIONS_KEYS

    # This method is used for setting configuration options.
    def configure
      yield self
    end

    # Create a hash of configuration options.
    def options
      OPTIONS_KEYS.map { |key, _| [key, send(key)] }.to_h
    end

    # Reset all options to their default values.
    def reset
      DEFAULTS.each do |key, val|
        send(key + "=", val)
      end
    end

    # Set a default value for the option that has not been set.
    def set_defaults
      DEFAULTS.each do |key, val|
        send(key + "=", send(key) || val)
      end
    end
  end
end
