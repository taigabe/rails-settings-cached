module RailsSettings
  module Fields
    class Base < Struct.new(:scope, :key, :default, :parent, :readonly, :separator, :type, :options)
      SEPARATOR_REGEXP = /[\n,;]+/

      # def initialize(scope:, key:, default:, parent:, readonly:, separator:, type:, options:)
      def initialize(args = {})
        self.scope = args[:scope]
        self.key = args[:key]
        self.default = args[:default]
        self.parent = args[:parent]
        self.readonly = !!args[:readonly]
        self.separator = args[:separator] || SEPARATOR_REGEXP
        self.type = args[:type] || :string
        self.options = args[:options]
      end

      def save!(value:)
        serialized_value = serialize(value)
        parent_record = parent.where(var: key).first || parent.new(var: key)
        parent_record.value = serialized_value
        parent_record.save!
        parent_record.value
      end

      def saved_value
        return parent.send(:_all_settings)[key] if table_exists?

        # Fallback to default value if table was not ready (before migrate)
        puts(
          "WARNING: table: \"#{parent.table_name}\" does not exist or not database connection, `#{parent.name}.#{key}` fallback to returns the default value."
        )
        nil
      end

      def default_value
        default.is_a?(Proc) ? default.call : default
      end

      def read
        return deserialize(default_value) if readonly || saved_value.nil?

        deserialize(saved_value)
      end

      def deserialize(value)
        raise NotImplementedError
      end

      def serialize(value)
        raise NotImplementedError
      end

      def to_h
        super.slice(:scope, :key, :default, :type, :readonly, :options)
      end

      def table_exists?
        parent.table_exists?
      rescue StandardError
        false
      end

      class << self
        def generate(**args)
          fetch_field_class(args[:type]).new(**args)
        end

        private

        def fetch_field_class(type)
          field_class_name = type.to_s.split("_").map(&:capitalize).join("")
          begin
            const_get("::RailsSettings::Fields::#{field_class_name}")
          rescue StandardError
            ::RailsSettings::Fields::String
          end
        end
      end
    end
  end
end
