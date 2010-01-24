$: << File.join(File.dirname(__FILE__), '..', 'lib')
$: << File.dirname(__FILE__)

require 'rubygems'
require 'test/unit'
require 'active_record'
require 'shoulda'
require 'mocha'
require 'scrubby'
begin; require 'redgreen'; rescue LoadError; end

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => File.join(File.dirname(__FILE__), 'test.db')
)

class CreateSchema < ActiveRecord::Migration
  def self.up
    create_table :users, :force => true do |t|
      t.string :type
      t.string :first_name
      t.string :last_name
      t.timestamps
    end
  end
end

CreateSchema.suppress_messages do
  CreateSchema.migrate(:up)
end

class User < ActiveRecord::Base
end

class Admin < User
end
