class AdditionalExamsController < ApplicationController
  before_filter :query_data
  filter_access_to :all

  def show
    @additional_exam = AdditionalExam.find params[:id], :include => :additional_exam_group
    additional_exam_subject = Subject.find(@additional_exam.subject_id)

    @students = @additional_exam.additional_exam_group.students
    unless  additional_exam_subject.elective_group_id.nil?
      assigned_students_subject = StudentsSubject.find_all_by_subject_id(additional_exam_subject.id)
      assigned_students=       assigned_students_subject .map{|s| s.student}
      assigned_students_with_exam=assigned_students&@students
      @students= assigned_students_with_exam
    end
    @config = Configuration.get_config_value('ExamResultType') || 'Marks'

    @grades = @batch.grading_level_list
  end

  def edit
    @additional_exam = AdditionalExam.find params[:id], :include => :additional_exam_group
    @subjects = @additional_exam_group.batch.subjects
  end

  def new
    @additional_exam = AdditionalExam.new
    @subjects = @batch.subjects
  end

  def save_additional_scores
    @additional_exam = AdditionalExam.find(params[:id])
    @additional_exam_group = @additional_exam.additional_exam_group
    
    params[:additional_exam].each_pair do |student_id, details|
      @additional_exam_score = AdditionalExamScore.find(:first, :conditions => {:additional_exam_id => @additional_exam.id, :student_id => student_id} )
      if @additional_exam_score.nil?

        AdditionalExamScore.create do |score|
          score.additional_exam_id          = @additional_exam.id
          score.student_id       = student_id
          score.marks            = details[:marks]
          score.grading_level_id = details[:grading_level_id]
          score.remarks          = details[:remarks]
        end
      else
        @additional_exam_score.update_attributes(details)
      end
    end
    flash[:notice] = 'Additional exam scores updated.'
    redirect_to [@additional_exam_group, @additional_exam]
  end

  def create
    @additional_exam = AdditionalExam.new(params[:additional_exam])
    @additional_exam.additional_exam_group_id = @additional_exam_group.id
    if @additional_exam.save
      flash[:notice] = "New exam created successfully."
      redirect_to [@batch, @additional_exam_group]
    else
      @subjects = @batch.subjects
      render 'new'
    end
  end


  def update
    @additional_exam = AdditionalExam.find params[:id], :include => :additional_exam_group

    if @additional_exam.update_attributes(params[:exam])
      flash[:notice] = 'Updated additional exam details successfully.'
      redirect_to [@additional_exam_group, @additional_exam]
    else
      render 'edit'
    end
  end

    def destroy
    @additional_exam = AdditionalExam.find params[:id], :include => :additional_exam_group
    batch_id = @additional_exam.additional_exam_group.batch_id
    batch_event = BatchEvent.find_by_event_id_and_batch_id(@additional_exam.event_id,batch_id)
    event = Event.find(@additional_exam.event_id)
    event.destroy
    batch_event.destroy
    @additional_exam.destroy
    redirect_to [@batch, @additional_exam_group]
  end

  private
  def query_data
    @additional_exam_group = AdditionalExamGroup.find(params[:additional_exam_group_id], :include => :batch)
    @batch = @additional_exam_group.batch
    @course = @batch.course
  end




end
