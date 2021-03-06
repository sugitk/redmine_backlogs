class AddBoardOptions < ActiveRecord::Migration
  def self.up
    unless ActiveRecord::Base.connection.column_exists?(:rb_genericboards, :boardoptions)
      add_column :rb_genericboards, :boardoptions, :text
    end
  end

  def self.down
    remove_column :rb_genericboards, :boardoptions
  end
end
