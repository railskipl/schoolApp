class StudentCategory < ActiveRecord::Base

  has_many :students
  has_many :fee_category ,:class_name =>"FinanceFeeCategory"

  validates_presence_of :name
  validates_uniqueness_of :name,:case_sensitive => false

  def before_destroy
    students = Student.find_all_by_student_category_id self
    students.each { |s| s.student_category_id = nil }
  end
end

# == Schema Information
#
# Table name: student_categories
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)
#  is_deleted :boolean(1)
#

