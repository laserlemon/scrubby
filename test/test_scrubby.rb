require 'helper'

class TestScrubby < Test::Unit::TestCase
  context 'Scrubbing' do
    context 'an attribute' do
      setup do
        User.scrub(:first_name)
        @user = User.new
      end

      should 'strip string values' do
        first_name = 'Steve '
        @user.first_name = first_name
        assert_equal first_name.strip, @user.first_name
      end

      should 'nuke blank string values' do
        first_name = ' '
        @user.first_name = first_name
        assert_nil @user.first_name
      end

      should 'not edit the given value in place' do
        first_name = 'Steve '
        value = first_name.dup
        @user.first_name = value
        assert_equal first_name, value
      end

      should 'clean the underlying attribute' do
        first_name = 'Steve '
        @user.first_name = first_name
        assert_not_equal first_name, @user.first_name
        assert_equal @user.first_name, @user.attributes['first_name']
      end

      context 'with a block' do
        setup do
          @block = proc{|v| v.titleize }
          User.scrub(:first_name, &@block)
          @user = User.new
        end

        should 'not strip string values' do
          first_name = 'Steve '
          @user.first_name = first_name
          assert_equal first_name, @user.first_name
        end

        should 'not nuke blank string values' do
          first_name = ' '
          @user.first_name = first_name
          assert_equal first_name, @user.first_name
        end

        should 'use the the block' do
          first_name = 'steve'
          @user.first_name = first_name
          assert_equal @block.call(first_name), @user.first_name
        end

        context 'having zero arity' do
          setup do
            User.scrub(:first_name){ nil }
            @user = User.new
          end

          should 'work just fine' do
            assert_nothing_raised do
              @user.first_name = 'Steve'
            end
          end
        end
      end
    end

    context 'a virtual attribute' do
      setup do
        User.class_eval do
          attr_accessor :middle_name
          scrub :middle_name
        end
        @user = User.new
      end

      should 'clean the value' do
        middle_name = ' Joel Michael '
        @user.middle_name = middle_name
        assert_not_equal middle_name, @user.middle_name
      end
    end

    context 'an invalid attribute' do
      setup do
        User.scrub(:middle_name)
        @user = User.new
      end

      should 'do nothing' do
        assert_nothing_raised do
          @user.update_attributes(:first_name => 'Steve', :last_name => 'Richert')
        end
      end
    end

    context 'multiple attributes' do
      setup do
        User.scrub(:first_name, :last_name)
        @user = User.new
      end

      should 'clean all values' do
        first_name, last_name = ' Steve', 'Richert '
        @user.first_name, @user.last_name = first_name, last_name
        assert_not_equal first_name, @user.first_name
        assert_not_equal last_name, @user.last_name
      end
    end

    context 'over multiple declarations' do
      setup do
        User.scrub(:first_name)
        User.scrub(:last_name)
        @user = User.new
      end

      should 'respect all scrubbers' do
        assert_same_elements %w(first_name last_name), User.scrubbers.keys
      end
    end

    context 'an inherited model' do
      setup do
        User.scrub(:first_name)
        User.inherited(Admin) # Reinitializes the scrubber inheritance
        Admin.scrub(:last_name)
      end

      should 'respect all scrubbers' do
        assert_same_elements %w(first_name last_name), Admin.scrubbers.keys
      end

      should 'not add a parent scrubber' do
        assert_same_elements %w(first_name), User.scrubbers.keys
      end

      context 'with overlapping attributes' do
        setup do
          @value = nil
          User.scrub(:first_name)
          @user = User.new
          User.inherited(Admin) # Reinitializes the scrubber inheritance
          Admin.scrub(:first_name){ @value }
          @admin = Admin.new
        end

        should 'give priority to the inherited scrubber' do
          first_name = 'Steve'
          assert_not_equal @value, first_name
          @admin.first_name = first_name
          assert_equal @value, @admin.first_name
        end

        should 'not clobber the parent scrubber' do
          first_name = 'Steve'
          assert_not_equal @value, first_name
          @user.first_name = first_name
          assert_not_equal @value, @user.first_name
        end
      end
    end

    teardown do
      User.inheritable_attributes.delete(:scrubbers)
      Admin.inheritable_attributes.delete(:scrubbers)
    end
  end
end
