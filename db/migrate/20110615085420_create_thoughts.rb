class CreateThoughts < ActiveRecord::Migration
  def self.up
    create_table :thoughts do |t|
      t.text :today_thought

      t.timestamps
    end
  end

  def self.down
    drop_table :thoughts
  end
end
