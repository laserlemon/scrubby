module Scrubby
  def self.included(base)
    base.class_eval do
      class_inheritable_hash :scrubbers
      self.scrubbers = {}

      extend ClassMethods
      include InstanceMethods

      alias_method_chain :write_attribute, :scrub
    end
  end

  module ClassMethods
    def scrub(*attributes, &block)
      scrubber = block_given? ? block : instance_method(:scrub)
      self.scrubbers = attributes.inject({}){|s,a| s.merge!(a.to_s => scrubber) }

      attributes.reject{|a| column_names.include?(a.to_s) }.each do |virtual_attribute|
        unless instance_methods.include?("#{virtual_attribute}_with_scrub=")
          define_method "#{virtual_attribute}_with_scrub=" do |value|
            scrubber = scrubbers[virtual_attribute.to_s]
            value = scrubber.bind(self).call(value)
            send("#{virtual_attribute}_without_scrub=", value)
          end

          alias_method_chain "#{virtual_attribute}=", :scrub
        end
      end
    end
  end

  module InstanceMethods
    def write_attribute_with_scrub(attribute, value)
      if scrubber = scrubbers[attribute.to_s]
        value = scrubber.bind(self).call(value)
      end

      write_attribute_without_scrub(attribute, value)
    end

    def scrub(value)
      value = value.dup if value.duplicable?

      case value
        when String
          value.strip!
          value.blank? ? nil : value
        else
          value
      end
    end
  end
end

ActiveRecord::Base.send(:include, Scrubby)
