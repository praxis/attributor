

module Attributor
  class String
    include Type

    def self.native_type
      return ::String
    end

    def self.example(options={})
      if options[:regexp]
        return options[:regexp].gen
      end

      return nil
    end

  end
end

# class << self

#   def validate(value,context,definition)
#     errors = []
#     definition.options.each do |opt, opt_value|
#       case opt
#       when :regexp
#         match = opt_value =~ value
#         errors << "#{context} value does not match regexp" unless match
#       end
#     end
#     errors
#   end

#   def decode( value, context , definition)
#     errors = []
#     if( value.is_a? ::String)
#       decoded = value
#     else
#       errors << "Do not know how to load a string from #{value.class.name}"
#     end
#     [ decoded, errors ]
#   end

#   def native_type
#     return ::String
#   end

# def example

#   if options.has_key? :example
#     value = options[:example]
#     if value.kind_of? Regexp
#       return value.gen
#     end
#     return value
#   end

#   return options[:regexp].gen if options[:regexp]
#   return super if options.has_key?(:default) || options.has_key?(:value)
#   return nil
# end

