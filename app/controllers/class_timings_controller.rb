class ClassTimingsController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  def index
    @batches = Batch.active
    @class_timings = ClassTiming.default
  end

  def new
    @class_timing = ClassTiming.new
    @batch = Batch.find params[:id] if request.xhr? and params[:id]
    respond_to do |format|
      format.js { render :action => 'new' }
    end
  end

  def create
    @class_timing = ClassTiming.new(params[:class_timing])
    @batch = @class_timing.batch
    respond_to do |format|
      if @class_timing.save
        @class_timing.batch.nil? ?
          @class_timings = ClassTiming.default :
          @class_timings = ClassTiming.for_batch(@class_timing.batch_id)
      #  flash[:notice] = 'Class timing was successfully created.'
        format.html { redirect_to class_timing_url(@class_timing) }
        format.js { render :action => 'create' }
      else
        @error = true
        format.html { render :action => "new" }
        format.js { render :action => 'create' }
      end
    end
  end

  def edit
    @class_timing = ClassTiming.find(params[:id])
    respond_to do |format|
      format.html { }
      format.js { render :action => 'edit' }
    end
  end

  def update
    @class_timing = ClassTiming.find params[:id]
    respond_to do |format|
      if @class_timing.update_attributes(params[:class_timing])
        @class_timing.batch.nil? ?
          @class_timings = ClassTiming.default :
          @class_timings = ClassTiming.for_batch(@class_timing.batch_id)
   #     flash[:notice] = 'Class timing updated successfully.'
        format.html { redirect_to class_timing_url(@class_timing) }
        format.js { render :action => 'update' }
      else
        @error = true
        format.html { render :action => "new" }
        format.js { render :action => 'create' }
      end
    end
  end

  def show
    @batch = nil
    if params[:batch_id] == ''
      @class_timings = ClassTiming.default
    else
      @class_timings = ClassTiming.for_batch(params[:batch_id])
      @batch = Batch.find params[:batch_id] unless params[:batch_id] == ''
    end
    respond_to do |format|
      format.js { render :action => 'show' }
    end
  end

  def destroy
    @class_timing = ClassTiming.find params[:id]
    @class_timing.destroy
  end

end
