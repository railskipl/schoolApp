class ExamGroup < ActiveRecord::Base
  validates_presence_of :name

  belongs_to :batch
  belongs_to :grouped_exam

  has_many :exams
  
  accepts_nested_attributes_for :exams

  attr_accessor :maximum_marks, :minimum_marks, :weightage

  def before_save
    self.exam_date = self.exam_date || Date.today
  end

  def batch_average_marks(marks)
    batch = self.batch
    exams = self.exams
    batch_students = batch.students
    total_students_marks = 0
 #   total_max_marks = 0
    students_attended = []
    exams.each do |exam|
      batch_students.each do |student|
        exam_score = ExamScore.find_by_student_id_and_exam_id(student.id,exam.id)
        unless exam_score.nil?
          total_students_marks = total_students_marks+exam_score.marks
          unless students_attended.include? student.id
            students_attended.push student.id
          end
        end
      end
      #      total_max_marks = total_max_marks+exam.maximum_marks
    end
    unless students_attended.size == 0
      batch_average_marks = total_students_marks/students_attended.size
    else
      batch_average_marks = 0
    end
    return batch_average_marks if marks == 'marks'
    #   return total_max_marks if marks == 'percentage'
  end

  def batch_average_percentage
    
  end

  def subject_wise_batch_average_marks(subject_id)
    batch = self.batch
    subject = Subject.find(subject_id)
    exam = Exam.find_by_exam_group_id_and_subject_id(self.id,subject.id)
    batch_students = batch.students
    total_students_marks = 0
    #   total_max_marks = 0
    students_attended = []

    batch_students.each do |student|
      exam_score = ExamScore.find_by_student_id_and_exam_id(student.id,exam.id)
      unless exam_score.nil?
        total_students_marks = total_students_marks+exam_score.marks
        unless students_attended.include? student.id
          students_attended.push student.id
        end
      end
    end
    #      total_max_marks = total_max_marks+exam.maximum_marks
    unless students_attended.size == 0
      subject_wise_batch_average_marks = total_students_marks/students_attended.size.to_f
    else
      subject_wise_batch_average_marks = 0
    end
    return subject_wise_batch_average_marks
    #   return total_max_marks if marks == 'percentage'
  end

  def total_marks(student)
    exams = Exam.find_all_by_exam_group_id(self.id)
    total_marks = 0
    max_total = 0
    exams.each do |exam|
      exam_score = ExamScore.find_by_exam_id_and_student_id(exam.id,student.id)
      total_marks = total_marks + exam_score.marks unless exam_score.nil?
      max_total = max_total + exam.maximum_marks unless exam_score.nil?
    end
    result = [total_marks,max_total]
  end

    def archived_total_marks(student)
    exams = Exam.find_all_by_exam_group_id(self.id)
    total_marks = 0
    max_total = 0
    exams.each do |exam|
      exam_score = ArchivedExamScore.find_by_exam_id_and_student_id(exam.id,student.id)
      total_marks = total_marks + exam_score.marks unless exam_score.nil?
      max_total = max_total + exam.maximum_marks unless exam_score.nil?
    end
    result = [total_marks,max_total]
  end

end
# == Schema Information
#
# Table name: exam_groups
#
#  id               :integer(4)      not null, primary key
#  name             :string(255)
#  batch_id         :integer(4)
#  exam_type        :string(255)
#  is_published     :boolean(1)      default(FALSE)
#  result_published :boolean(1)      default(FALSE)
#  exam_date        :date
#

