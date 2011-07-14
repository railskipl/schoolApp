class AddDescriptionToHomeworks < ActiveRecord::Migration
  def self.up
    add_column :homeworks, :description, :text
  end

  def self.down
    remove_column :homeworks, :description
  end
end
