module Barrister
  class Error < StandardError
    MESSAGES = {
      :not_found => <<-EOS.gsub(/^\s{2,}/, "")
        A config file could not be found.
        Please put a 'config.yml' file
        in the #{File.expand_path('../../bin', __FILE__)} directory.
      EOS
    }
  end

  # If an IO operation fails, this error is raised.
  IOError = Class.new(Error)
end
