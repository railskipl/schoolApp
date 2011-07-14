class AddAttachmentsEmpPhotoToEmployee < ActiveRecord::Migration
  def self.up
    add_column :employees, :emp_photo_file_name, :string
    add_column :employees, :emp_photo_content_type, :string
    add_column :employees, :emp_photo_file_size, :integer
    add_column :employees, :emp_photo_updated_at, :datetime
  end

  def self.down
    remove_column :employees, :emp_photo_file_name
    remove_column :employees, :emp_photo_content_type
    remove_column :employees, :emp_photo_file_size
    remove_column :employees, :emp_photo_updated_at
  end
end
