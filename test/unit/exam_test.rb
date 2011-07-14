require File.expand_path(File.dirname(__FILE__) + './../test_helper')

class ExamTest < ActiveSupport::TestCase
  fixtures :users

  should_belong_to :exam_group
  should_belong_to :subject

  context 'a new exam record' do
    setup do
      @exam = Factory.build(:exam)
      @exam_group = Factory.create(:exam_group, :exam_date => Date.today)
      @exam.exam_group = @exam_group
    end

    should 'validate presence of maximum marks' do
      @exam.maximum_marks = nil
      assert_invalid @exam
    end

    should 'validate presence of minimum marks' do
      @exam.minimum_marks = nil
      assert_invalid @exam
    end

    should 'not have minimum marks more than maximum marks' do
      @exam.maximum_marks = 50
      @exam.minimum_marks = 51
      assert_invalid @exam
    end

  end

  context 'an existing exam record' do
    setup do
      @exam_group = Factory.create(:exam_group, :exam_date => Date.today)
      @course = Factory.create(:course)
      @batch = @course.batches.first
      @subject = Factory.create(:subject, :batch_id => @batch.id)
      @exam = Factory.create(:exam, 
        :exam_group_id => @exam_group.id,
        :subject_id => @subject.id)
    end

    should 'update exam group date if this date is earlier' do
      @exam.update_attribute(:start_time, Time.now - 2.days)
      assert_equal @exam_group.exam_date, (Date.today - 2.days)
    end

    should 'not update exam group date if this date is later' do
      @exam.update_attribute :start_time, Time.now + 2.days
      assert_equal @exam_group.exam_date, (Date.today)
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

