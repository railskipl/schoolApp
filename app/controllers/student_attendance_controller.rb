class StudentAttendanceController < ApplicationController
  before_filter :login_required
#  before_filter :protect_other_student_data

 
  def index
  end

  def student
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @student = Student.find(params[:id])
    @batch = Batch.find(@student.batch_id)
    @subjects = Subject.find_all_by_batch_id(@batch.id,:conditions=>'is_deleted = false')
    
    if request.post?
      @detail_report = []
      if params[:advance_search][:mode]== 'Overall'
        @start_date = @batch.start_date.to_date
        @end_date = Date.today
        unless @config.config_value == 'Daily'
          unless params[:advance_search][:subject_id].empty?
            @subject = Subject.find params[:advance_search][:subject_id]
            @report = PeriodEntry.find_all_by_subject_id(@subject.id,  :conditions =>{:month_date => @start_date..@end_date})
          else
            @report = PeriodEntry.find_all_by_batch_id(@batch.id,  :conditions =>{:month_date => @start_date..@end_date})
          end
        else
          @report = PeriodEntry.find_all_by_batch_id(@batch.id,  :conditions =>{:month_date => @start_date..@end_date})
        end
      else
        @month = params[:advance_search][:month]
        @year = params[:advance_search][:year]
        @start_date = "01-#{@month}-#{@year}".to_date
        #        @start_date = @date
        @today = Date.today
        @end_date = @start_date.end_of_month
        if @end_date > Date.today
          @end_date = Date.today
        end
        unless @config.config_value == 'Daily'
          unless params[:advance_search][:subject_id].empty?
            @subject = Subject.find params[:advance_search][:subject_id]
            @report = PeriodEntry.find_all_by_subject_id(@subject.id,  :conditions =>{:month_date => @start_date..@end_date})
          else
            @report = PeriodEntry.find_all_by_batch_id(@batch.id,  :conditions =>{:month_date => @start_date..@end_date})
          end
        else
          @report = PeriodEntry.find_all_by_batch_id(@batch.id,  :conditions =>{:month_date => @start_date..@end_date})
        end
      end
      
      render :update do |page|
        page.replace_html 'report', :partial => 'report'
      end
    end
    
  end

  def month
    if params[:mode] == 'Monthly'
      @year = Date.today.year
      render :update do |page|
        page.replace_html 'month', :partial => 'month'
      end
    else
      render :update do |page|
        page.replace_html 'month', :text =>''
      end
    end
  end

  def student_report
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @student = Student.find(params[:id])
    @batch = Batch.find(params[:year])
    @start_date = @batch.start_date.to_date
    @end_date =  @batch.end_date.to_date
    @report = PeriodEntry.find_all_by_batch_id(@batch.id,  :conditions =>{:month_date => @start_date..@end_date})

end

end