class Exam < ActiveRecord::Base
#  validates_presence_of :maximum_marks
#  validates_presence_of :minimum_marks
  validates_presence_of :start_time
  validates_presence_of :end_time

  belongs_to :exam_group
  belongs_to :subject, :conditions => { :is_deleted => false }

  belongs_to :event

  has_many :exam_scores
   has_many :archived_exam_scores

  accepts_nested_attributes_for :exam_scores

  def validate
    errors.add(:minimum_marks, "can't be more than max marks.") \
      if minimum_marks and maximum_marks and minimum_marks > maximum_marks
  end

  def before_save
    self.weightage = 0 if self.weightage.nil?
    #update_exam_group_date
  end

  def after_save
    update_exam_event
  end

  def score_for(student_id)
    exam_score = self.exam_scores.find(:first, :conditions => { :student_id => student_id })
    exam_score.nil? ? ExamScore.new : exam_score
  end

  def class_average_marks
    results = ExamScore.find_all_by_exam_id(self)
    scores = results.collect { |x| x.marks unless x.marks.nil?}
    return (scores.sum / scores.size) unless scores.size == 0
    return 0
  end

  private
  def update_exam_group_date
    group = self.exam_group
    group.update_attribute(:exam_date, self.start_time.to_date) if !group.exam_date.nil? and self.start_time.to_date < group.exam_date
  end

  def update_exam_event
    if self.event.nil?
      new_event = Event.create do |e|
        e.title       = "Exam"
        e.description = "#{self.exam_group.name} for #{self.subject.batch.full_name} - #{self.subject.name}"
        e.start_date  = self.start_time
        e.end_date    = self.end_time
        e.is_exam     = true
      end
      batch_event = BatchEvent.create do |be|
        be.event_id = new_event.id
        be.batch_id = self.exam_group.batch_id
      end
      #self.event_id = new_event.id
      self.update_attributes(:event_id=>new_event.id)
    else
      self.event.update_attributes(:start_date => self.start_time, :end_date => self.end_time)
    end
  end

end
# == Schema Information
#
# Table name: exams
#
#  id               :integer(4)      not null, primary key
#  exam_group_id    :integer(4)
#  subject_id       :integer(4)
#  start_time       :datetime
#  end_time         :datetime
#  maximum_marks    :integer(4)
#  minimum_marks    :integer(4)
#  grading_level_id :integer(4)
#  weightage        :integer(4)      default(0)
#  event_id         :integer(4)
#  created_at       :datetime
#  updated_at       :datetime
#

