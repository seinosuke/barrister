module Barrister
  module Extension

    refine Hash do
      def symbolize_keys!
        keys.each do |key|
          case val = delete(key)
          when Hash then val.symbolize_keys!
          when Array then val.map!{ |v| v.symbolize_keys! rescue v }
          end
          self[(key.to_sym rescue key) || key] = val
        end
        self
      end
    end
  end
end
