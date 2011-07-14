class EmployeeDepartment < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name, :code
  has_many :employees


  def department_total_salary(start_date,end_date)
    total = 0
    self.employees.each do |e|
      salary_dates = e.all_salaries(start_date,end_date)
      salary_dates.each do |s|
        total += e.employee_salary(s.salary_date.to_date)
      end
    end
    total
  end

end

# == Schema Information
#
# Table name: employee_departments
#
#  id     :integer(4)      not null, primary key
#  code   :string(255)
#  name   :string(255)
#  status :boolean(1)
#

