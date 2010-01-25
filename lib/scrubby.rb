# +scrubby+ cleans up incoming ActiveRecord model attributes by hijacking attribute setters and
# reformatting the attribute value before passing it along to be set as usual.
#
# Author:: Steve Richert
# Copyright:: Copyright (c) 2010 Steve Richert
# License:: MIT License (http://www.opensource.org/licenses/mit-license.php)
#
# To enable scrubbing on a model, simply use the +scrub+ method:
#
#   class User < ActiveRecord::Base
#     scrub :name
#   end
#
#   user = User.new(:name => " Steve Richert ")
#   user.name # => "Steve Richert"
#   noname = User.new(:name => " ")
#   noname.name # => nil
#
# See the +scrub+ class method documentation for more details.
module Scrubby
  def self.included(base) #:nodoc:
    base.class_eval do
      class_inheritable_hash :scrubbers
      self.scrubbers = {}

      extend ClassMethods
      include InstanceMethods

      alias_method_chain :write_attribute, :scrub
    end
  end

  module ClassMethods
    # +scrub+ accepts multiple symbol or string arguments, representing model attributes that are
    # to be scrubbed before being set. The +scrub+ method accepts no options, but an optional block
    # can be included which will be used for scrubbing. Otherwise, the +scrub+ instance method is
    # used.
    #
    # The +scrub+ instance method and the optional block both expect one argument: the incoming
    # attribute value, and should return one value: the new, all-cleaned-up attribute value.
    # However, when a custom block is given, the single argument can be left out if for some
    # reason it's not needed.
    #
    # == Examples
    #
    #   class User < ActiveRecord::Base
    #     scrub :first_name, :last_name
    #   end
    #
    #   class User < ActiveRecord::Base
    #     scrub :first_name, :last_name do |value|
    #       value.blank? ? nil : value.titleize
    #     end
    #   end
    #
    #   class User < ActiveRecord::Base
    #     scrub(:first_name){|v| v.to_s.upcase }
    #     scrub(:last_name){ nil }
    #   end
    #
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
    # An alias of the +write_attribute+ method, +write_attribute_with_scrub+ will check whether a
    # scrubber exists for the given attribute and if so, scrub the given value before passing it
    # on to the original +write_attribute+ method.
    #
    # This is used for column-based attributes, while virtual attributes are handled by aliasing
    # the corresponding setter methods and scrubbing there.
    def write_attribute_with_scrub(attribute, value)
      if scrubber = scrubbers[attribute.to_s]
        value = scrubber.bind(self).call(value)
      end

      write_attribute_without_scrub(attribute, value)
    end

    # The +scrub+ instance method is the default way in which incoming values are cleaned. By
    # default, the behavior is to strip string values and to return nil for blank strings.
    #
    # If a different behavoir is required, this method can be overridden at the ActiveRecord::Base
    # level and/or at the level of any of ActiveRecord's inherited models.
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
