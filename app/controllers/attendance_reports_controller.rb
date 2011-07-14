class AttendanceReportsController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  def index
    @batches = Batch.active
    @config = Configuration.find_by_config_key('StudentAttendanceType')
  end

  def subject
    @batch = Batch.find params[:batch_id]
    @subjects = Subject.find_all_by_batch_id(@batch.id,:conditions=>'is_deleted = false')
    render :update do |page|
      page.replace_html 'subject', :partial => 'subject'
    end
  end

  def mode
    @batch = Batch.find params[:batch_id]
    unless params[:subject_id] == ''
      @subject = params[:subject_id]
    else
    @subject = 0
    end
    render :update do |page|
      page.replace_html 'mode', :partial => 'mode'
      page.replace_html 'month', :text => ''
    end
  end
  def show
    @batch = Batch.find params[:batch_id]
    @start_date = @batch.start_date.to_date
    @end_date = Date.today.to_date
    
    @mode = params[:mode]
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    unless @config.config_value == 'Daily'
      if @mode == 'Overall'
        @students = Student.find_all_by_batch_id(@batch.id)
        unless params[:subject_id] == '0'
          @subject = Subject.find params[:subject_id]
          @report = PeriodEntry.find_all_by_subject_id(@subject.id,  :conditions =>{:month_date => @start_date..@end_date})
        else
          @report = PeriodEntry.find_all_by_batch_id(@batch.id,  :conditions =>{:month_date => @start_date..@end_date})
        end
        render :update do |page|
          page.replace_html 'report', :partial => 'report'
          page.replace_html 'month', :text => ''
          page.replace_html 'year', :text => ''
        end
      else
        @year = Date.today.year
        @subject = params[:subject_id]
        render :update do |page|
          page.replace_html 'month', :partial => 'month'
        end
      end
    else
      if @mode == 'Overall'
        @students = Student.find_all_by_batch_id(@batch.id)
        @report = PeriodEntry.find_all_by_batch_id(@batch.id,  :conditions =>{:month_date => @start_date..@end_date})
        render :update do |page|
          page.replace_html 'report', :partial => 'report'
          page.replace_html 'month', :text => ''
          page.replace_html 'year', :text => ''
        end
      else
        @year = Date.today.year
        @subject = params[:subject_id]
        render :update do |page|
          page.replace_html 'month', :partial => 'month'
        end
      end
    end
  end
  def year
    @batch = Batch.find params[:batch_id]
    @subject = params[:subject_id]
    if request.xhr?
    @year = Date.today.year
    @month = params[:month]
    render :update do |page|
        page.replace_html 'year', :partial => 'year'
      end
    end
  end

  def report
    @batch = Batch.find params[:batch_id]
    @month = params[:month]
    @year = params[:year]
    @students = Student.find_all_by_batch_id(@batch.id)
      @config = Configuration.find_by_config_key('StudentAttendanceType')
#    @date = "01-#{@month}-#{@year}"
    @date = '01-'+@month+'-'+@year
    @start_date = @date.to_date
    @today = Date.today
    unless @start_date > Date.today
      if @month == @today.month.to_s
        @end_date = Date.today
      else
        @end_date = @start_date.end_of_month
      end
      
      if @config.config_value == 'Daily'
        @report = PeriodEntry.find_all_by_batch_id(@batch.id,  :conditions =>{:month_date => @start_date..@end_date})
      else
        unless params[:subject_id] == '0'
          @subject = Subject.find params[:subject_id]
          @report = PeriodEntry.find_all_by_subject_id(@subject.id,  :conditions =>{:month_date => @start_date..@end_date})
        else
          @report = PeriodEntry.find_all_by_batch_id(@batch.id,  :conditions =>{:month_date => @start_date..@end_date})
        end
      end
    else
      @report = ''
    end
    render :update do |page|
        page.replace_html 'report', :partial => 'report'
      end
  end

  def student_details
    @student = Student.find params[:id]
    @report = Attendance.find_all_by_student_id(@student.id)
  end

  def filter
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @batch = Batch.find(params[:filter][:batch])
    @students = Student.find_all_by_batch_id(@batch.id)
    @start_date = (params[:filter][:start_date]).to_date
    @end_date = (params[:filter][:end_date]).to_date
    @range = (params[:filter][:range])
    @value = (params[:filter][:value])
    if request.post?
      unless @config.config_value == 'Daily'
        unless params[:filter][:subject] == '0'
        @subject = Subject.find params[:filter][:subject]
        end
        if params[:filter][:subject] == '0'
          @report = PeriodEntry.find_all_by_batch_id(@batch.id,  :conditions =>{:month_date => @start_date..@end_date})
        else
          @report = PeriodEntry.find_all_by_subject_id(@subject.id,  :conditions =>{:month_date => @start_date..@end_date})
        end
      else
        @report = PeriodEntry.find_all_by_batch_id(@batch.id,  :conditions =>{:month_date => @start_date..@end_date})
      end
    end
  end

  def advance_search
    @batches = []
  end
end