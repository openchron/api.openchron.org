class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.string :title, :null => false
      t.datetime :from, :null => false
      t.integer :duration, :default => 0
      t.integer :from_granularity, :to_granularity, :default => 1

      t.timestamps
    end
  end

  def self.down
    drop_table :events
  end
end
