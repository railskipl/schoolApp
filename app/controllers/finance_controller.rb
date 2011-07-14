class FinanceController < ApplicationController
  before_filter :login_required

  def index
    @hr = Configuration.find_by_config_value("HR")
  end


  def automatic_transactions
    @triggers = FinanceTransactionTrigger.all
    @categories = FinanceTransactionCategory.find(:all ,:conditions => ["id != 1 and id != 3 "])
  end
  
  def donation
    @donation = FinanceDonation.new(params[:donation])
    if request.post? and @donation.save
      flash[:notice] = 'Donation accepted.'
      redirect_to :action => 'donation_receipt', :id => @donation.id
    end
  end

  def donation_receipt
    @donation = FinanceDonation.find(params[:id])
  end

  def donation_receipt_pdf
    @donation = FinanceDonation.find(params[:id])
    @currency_type = Configuration.find_by_config_key("CurrencyType").config_value
    respond_to do |format|
      format.pdf { render :layout => false }
    end
  end

  def donors
    @donations = FinanceDonation.find(:all, :order => 'created_at desc')
  end

  def expense_create
    flash[:notice]=nil
    @expense = FinanceTransaction.new(params[:transaction])
    @categories = FinanceTransactionCategory.expense_categories
    if @categories.empty?
      flash[:notice] = "Please create category for expense!"
    end
    if request.post? and @expense.save
      flash[:notice] = "Expense has been added to the accounts."
    end
  end

  def expense_edit
    @transaction = FinanceTransaction.find(params[:id])
    @categories = FinanceTransactionCategory.all(:conditions => {:is_income => false} )
    if request.post? and @transaction.update_attributes(params[:transaction])
      flash[:notice] = "The entry has been edited."
    end
  end
  def income_create
    flash[:notice]=nil
    @income = FinanceTransaction.new(params[:transaction])
    @categories = FinanceTransactionCategory.income_categories
    if @categories.empty?
      flash[:notice] = "Please create category for income!"
    end
    if request.post? and @income.save
      flash[:notice] = "Income has been added to the accounts."
    end
  end

  def monthly_income
      
  end

  def income_edit
    @transaction = FinanceTransaction.find(params[:id])
    @categories = FinanceTransactionCategory.all(:conditions => {:is_income => true} )
    if request.post? and @transaction.update_attributes(params[:transaction])
      flash[:notice] = "The entry has been edited."
    end
  end


  def categories
    @categories = FinanceTransactionCategory.all(:conditions => {:deleted => false})
  end

  def category_new
    @finance_transaction_category = FinanceTransactionCategory.new
  end
  
  def category_create
    @finance_category = FinanceTransactionCategory.create(params[:finance_category])
    @categories = FinanceTransactionCategory.all(:conditions => {:deleted => false})
  end

  def category_delete
    @finance_category = FinanceTransactionCategory.find(params[:id])
    @finance_category.update_attribute(:deleted => true)
    @categories = FinanceTransactionCategory.all(:conditions => {:deleted => false})
  end

  def category_edit
    @finance_category = FinanceTransactionCategory.find(params[:id])
    @categories = FinanceTransactionCategory.all
  end

  def category_update
    @finance_category = FinanceTransactionCategory.find(params[:id])
    @finance_category.update_attributes(params[:finance_category])
    @categories = FinanceTransactionCategory.all
  end

  def transaction_trigger_create
    @trigger = FinanceTransactionTrigger.create(params[:transaction_trigger])
    @triggers = FinanceTransactionTrigger.all
    render :update do |page|
      page.replace_html 'transaction-triggers-list', :partial => 'transaction_triggers_list'
    end
  end

  #transaction-----------------------

  
  def update_monthly_report

    @hr = Configuration.find_by_config_value("HR")
    @start_date = (params[:start_date]).to_date
    @end_date = (params[:end_date]).to_date
    @transactions = FinanceTransaction.find(:all,
      :order => 'created_at desc', :conditions => ["created_at >= '#{@start_date}' and created_at <= '#{@end_date}'"])
    @other_transactions = FinanceTransaction.report(@start_date,@end_date,params[:page])
    @transactions_fees = FinanceTransaction.total_fees(@start_date,@end_date)
    employees = Employee.find(:all)
    @salary = Employee.total_employees_salary(employees, @start_date, @end_date)
    @donations_total = FinanceTransaction.donations_triggers(@start_date,@end_date)
    @batchs = Batch.find(:all)
    @grand_total = FinanceTransaction.grand_total(@start_date,@end_date)
    @graph = open_flash_chart_object(960, 500, "graph_for_update_monthly_report?start_date=#{@start_date}&end_date=#{@end_date}")

  end
  
  
  def transaction_pdf
    @currency_type = Configuration.find_by_config_key("CurrencyType").config_value
    @hr = Configuration.find_by_config_value("HR")
    @start_date = (params[:start_date]).to_date
    @end_date = (params[:end_date]).to_date
    @transactions = FinanceTransaction.find(:all,
      :order => 'created_at desc', :conditions => ["created_at >= '#{@start_date}' and created_at <= '#{@end_date}'"])
    @other_transactions = FinanceTransaction.report(@start_date,@end_date,params[:page])
    @transactions_fees = FinanceTransaction.total_fees(@start_date,@end_date)
    employees = Employee.find(:all)
    @salary = Employee.total_employees_salary(employees, @start_date, @end_date)
    @donations_total = FinanceTransaction.donations_triggers(@start_date,@end_date)
    @batchs = Batch.find(:all)
    @grand_total = FinanceTransaction.grand_total(@start_date,@end_date)
    respond_to do |format|
      format.pdf { render :layout => false }
    end

  end

  def salary_department
    month_date
    @departments = EmployeeDepartment.find(:all)
    @monthly_payslips = MonthlyPayslip.find(:all,:order => 'salary_date desc', :conditions => ["salary_date >= '#{@start_date}' and salary_date <= '#{@end_date}' and is_approved = '1'"])

  end

  def salary_employee
    month_date
    @department = EmployeeDepartment.find(params[:id])
    @employees = @department.employees
    @monthly_payslips = MonthlyPayslip.find(:all,:order => 'salary_date desc', :conditions => ["salary_date >= '#{@start_date}' and salary_date <= '#{@end_date}' and is_approved = '1'"])

  end

  def employee_payslip_monthly_report
    
    @salary_date = params[:id2]
    @employee = Employee.find(params[:id])
    @currency_type = Configuration.find_by_config_key("CurrencyType").config_value
    
    if params[:salary_date] == ""
      render :update do |page|
        page.replace_html "payslip_view", :text => ""
      end
      return
    end
    @monthly_payslips = MonthlyPayslip.find_all_by_salary_date(@salary_date,
      :conditions=> "employee_id =#{params[:id]}",
      :order=> "payroll_category_id ASC")

    @individual_payslip_category = IndividualPayslipCategory.find_all_by_salary_date(@salary_date,
      :conditions=>"employee_id =#{params[:id]}",
      :order=>"id ASC")
    @individual_category_non_deductionable = 0
    @individual_category_deductionable = 0
    @individual_payslip_category.each do |pc|
      unless pc.is_deduction == true
        @individual_category_non_deductionable = @individual_category_non_deductionable + pc.amount.to_i
      end
    end

    @individual_payslip_category.each do |pc|
      unless pc.is_deduction == false
        @individual_category_deductionable = @individual_category_deductionable + pc.amount.to_i
      end
    end

    @non_deductionable_amount = 0
    @deductionable_amount = 0
    @monthly_payslips.each do |mp|
      category1 = PayrollCategory.find(mp.payroll_category_id)
      unless category1.is_deduction == true
        @non_deductionable_amount = @non_deductionable_amount + mp.amount.to_i
      end
    end

    @monthly_payslips.each do |mp|
      category2 = PayrollCategory.find(mp.payroll_category_id)
      unless category2.is_deduction == false
        @deductionable_amount = @deductionable_amount + mp.amount.to_i
      end
    end

    @net_non_deductionable_amount = @individual_category_non_deductionable + @non_deductionable_amount
    @net_deductionable_amount = @individual_category_deductionable + @deductionable_amount

    @net_amount = @net_non_deductionable_amount - @net_deductionable_amount
   
  end

  def donations_report
    month_date
    @donations = FinanceTransaction.find(:all,:order => 'created_at desc', :conditions => ["created_at >= '#{@start_date}' and created_at <= '#{@end_date}'and category_id ='#{2}'"])
    @trigger = FinanceTransactionTrigger.find :all
  end

  def fees_report
    month_date
    #@fees = FinanceTransaction.find(:all,:order => 'created_at desc', :conditions => ["created_at >= '#{@start_date}' and created_at <= '#{@last_date}'and category_id ='#{3}'"])
    @batchs = Batch.find(:all)
  end

  def batch_fees_report
    month_date
    @fee_collection = FinanceFeeCollection.find(params[:id])
    @batch = Batch.find(@fee_collection.batch.id)
    @sids = @batch.students(&:id)
    @fees = FinanceFee.find_all_by_fee_collection_id(@fee_collection.id)
  end

  def student_fees_structure
    
    month_date
    @student = Student.find(params[:id])
    @components = @student.get_fee_strucure_elements
    
  end

  # approve montly payslip ----------------------

  def approve_monthly_payslip
    @salary_dates = MonthlyPayslip.find(:all, :select => "distinct salary_date")
    
  end

  def one_click_approve
    @dates = MonthlyPayslip.find_all_by_salary_date(params[:salary_date],:conditions => ["is_approved = 'false'"])
    @salary_date = params[:salary_date]
    render :update do |page|
      page.replace_html "approve",:partial=> "one_click_approve"
    end
  end

  def one_click_approve_submit
    dates = MonthlyPayslip.find_all_by_salary_date(Date.parse(params[:date]))

    dates.each do |d|
      d.approve(current_user.id)
    end
    flash[:notice] = 'Payslip has been approved'
    redirect_to :action => "index"
    
  end

  def employee_payslip_approve
    dates = MonthlyPayslip.find_all_by_salary_date_and_employee_id(Date.parse(params[:id2]),params[:id])

    dates.each do |d|
      d.approve(current_user.id)
    end
    flash[:notice] = 'Payslip has been approved'
    redirect_to :action => "index"
  end

  #view monthly payslip -------------------------------
  def view_monthly_payslip
    
    @departments = EmployeeDepartment.find(:all)
    @categories  = EmployeeCategory.find(:all)
    @positions   = EmployeePosition.find(:all)
    @grades      = EmployeeGrade.find(:all)
    
  end

  def view_monthly_payslip_search
    @employee = Employee.find(params[:id])
    @salary_dates = MonthlyPayslip.find_all_by_employee_id(params[:id], :select => "distinct salary_date")

  end

  def update_monthly_payslip
    @employee = Employee.find(params[:emp_id])
    @salary_date = params[:salary_date]
    @approve = @employee.is_paylip_approved(@salary_date)
    @currency_type = Configuration.find_by_config_key("CurrencyType").config_value
    
    if params[:salary_date] == ""
      render :update do |page|
        page.replace_html "payslip_view", :text => ""
      end
      return
    end
    @monthly_payslips = MonthlyPayslip.find_all_by_salary_date(params[:salary_date],
      :conditions=> "employee_id =#{params[:emp_id]}",
      :order=> "payroll_category_id ASC")

    @individual_payslip_category = IndividualPayslipCategory.find_all_by_salary_date(params[:salary_date],
      :conditions=>"employee_id =#{params[:emp_id]}",
      :order=>"id ASC")
    @individual_category_non_deductionable = 0
    @individual_category_deductionable = 0
    @individual_payslip_category.each do |pc|
      unless pc.is_deduction == true
        @individual_category_non_deductionable = @individual_category_non_deductionable + pc.amount.to_i
      end
    end

    @individual_payslip_category.each do |pc|
      unless pc.is_deduction == false
        @individual_category_deductionable = @individual_category_deductionable + pc.amount.to_i
      end
    end

    @non_deductionable_amount = 0
    @deductionable_amount = 0
    @monthly_payslips.each do |mp|
      category1 = PayrollCategory.find(mp.payroll_category_id)
      unless category1.is_deduction == true
        @non_deductionable_amount = @non_deductionable_amount + mp.amount.to_i
      end
    end

    @monthly_payslips.each do |mp|
      category2 = PayrollCategory.find(mp.payroll_category_id)
      unless category2.is_deduction == false
        @deductionable_amount = @deductionable_amount + mp.amount.to_i
      end
    end

    @net_non_deductionable_amount = @individual_category_non_deductionable + @non_deductionable_amount
    @net_deductionable_amount = @individual_category_deductionable + @deductionable_amount

    @net_amount = @net_non_deductionable_amount - @net_deductionable_amount
    render :update do |page|
      page.replace_html "payslip_view", :partial => "view_payslip"
    end

  end

  def search_ajax
    other_conditions = ""
    other_conditions += " AND employee_department_id = '#{params[:employee_department_id]}'" unless params[:employee_department_id] == ""
    other_conditions += " AND employee_category_id = '#{params[:employee_category_id]}'" unless params[:employee_category_id] == ""
    other_conditions += " AND employee_position_id = '#{params[:employee_position_id]}'" unless params[:employee_position_id] == ""
    other_conditions += " AND employee_grade_id = '#{params[:employee_grade_id]}'" unless params[:employee_grade_id] == ""
    @employee = Employee.find(:all,
      :conditions => "(first_name LIKE \'#{params[:query]}%\'
                       OR middle_name LIKE \'#{params[:query]}%\'
                       OR last_name LIKE \'#{params[:query]}%\'
                       OR ((first_name || \' \' || last_name) LIKE \'#{params[:query]}%\'))" + other_conditions,

      :order => "first_name asc") unless params[:query] == ''
    render :layout => false
  end

  #asset-liability-----------

  def create_liability
    @liability = Liability.create(params[:liability])
  end

  def edit_liability
    @liability = Liability.find(params[:id])
  end

  def update_liability
    @liability = Liability.find(params[:id])
    @liability.update_attributes(params[:liability])
    @liabilities = Liability.find(:all,:conditions => 'is_deleted = 0')
    render :update do |page|
      page.replace_html "liability_list", :partial => "liability_list"
    end
  end

  def view_liability
    @liabilities = Liability.find(:all,:conditions => "is_deleted = '0'")
  end
  
  def delete_liability
    @liability = Liability.find(params[:id])
    @liability.update_attributes(:is_deleted => true)
    @liabilities = Liability.find(:all ,:conditions => 'is_deleted = 0')
    render :update do |page|
      page.replace_html "liability_list", :partial => "liability_list"
    end
  end

  def each_liability_view
    @liability = Liability.find(params[:id])
    @currency_type = Configuration.find_by_config_key("CurrencyType").config_value
  end

  def create_asset
    @asset = Asset.create(params[:asset])
  end

  def view_asset
    @assets = Asset.find(:all,:conditions => "is_deleted = '0'")
  end

  def edit_asset
    @asset = Asset.find(params[:id])
  end

  def update_asset
    @asset = Asset.find(params[:id])
    @asset.update_attributes(params[:asset])
    @assets = Asset.find(:all,:conditions => 'is_deleted = 0')
    render :update do |page|
      page.replace_html "asset_list", :partial => "asset_list"
    end
  end

  def delete_asset
    @asset = Asset.find(params[:id])
    @asset.update_attributes(:is_deleted => true)
    @assets = Asset.all(:conditions => 'is_deleted = 0')
    render :update do |page|
      page.replace_html "asset_list", :partial => "asset_list"
    end
  end

  def each_asset_view
    @asset = Asset.find(params[:id])
    @currency_type = Configuration.find_by_config_key("CurrencyType").config_value
  end
  #fees ----------------

  def master_fees
    @finance_fee_category = FinanceFeeCategory.new
    @finance_fee_particular = FinanceFeeParticulars.new
    @batches = Batch.active
    @master_categories = FinanceFeeCategory.paginate(:page => params[:page],:conditions=> ["is_deleted = '#{false}' and is_master = '1'"])
    @student_categories = StudentCategory.find :all
  end
  
  def master_category_new
    @finance_fee_category = FinanceFeeCategory.new
    @batches = Batch.active
    respond_to do |format|
      format.js { render :action => 'master_category_new' }
    end
  end

  def master_category_create
    @finance_fee_category = FinanceFeeCategory.new(params[:finance_fee_category])
    @finance_fee_category.is_master = true
    unless @finance_fee_category.save
      @error = true
    end
    @master_categories = FinanceFeeCategory.paginate(:page => params[:page] ,:conditions=> ["is_deleted = '#{false}' and is_master = '1'"])
    respond_to do |format|
      format.js { render :action => 'master_category_create' }
    end
  end
  
  def master_category_edit
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    respond_to do |format|
      format.js { render :action => 'master_category_edit' }
    end
  end

  def master_category_update
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    @finance_fee_category.update_attributes(params[:finance_fee_category])
    @master_categories = FinanceFeeCategory.paginate(:page => params[:page], :conditions =>["is_deleted = '#{false}' and is_master = '1'"])
  end

  def master_category_particulars
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    @particulars = FinanceFeeParticulars.paginate(:page => params[:page],:conditions => ["is_deleted = '#{false}' and finance_fee_category_id = '#{@finance_fee_category.id}' "])
    respond_to do |format|
      format.js { render :action => 'master_category_particulars' }
    end
  end
  def master_category_particulars_edit
    @finance_fee_particulars= FinanceFeeParticulars.find(params[:id])
    respond_to do |format|
      format.js { render :action => 'master_category_particulars_edit' }
    end
  end

  def master_category_particulars_update
    @feeparticulars = FinanceFeeParticulars.find( params[:id])
    @feeparticulars.update_attributes(params[:finance_fee_particulars])
    @finance_fee_category = FinanceFeeCategory.find(@feeparticulars.finance_fee_category_id)
    @particulars = FinanceFeeParticulars.paginate(:page => params[:page],:conditions => ["is_deleted = '#{false}' and finance_fee_category_id = '#{@finance_fee_category.id}' "])
    respond_to do |format|
      format.js { render :action => 'master_category_particulars' }
    end
  end
  def master_category_particulars_delete
    @feeparticulars = FinanceFeeParticulars.find( params[:id])
    @feeparticulars.update_attributes(:is_deleted => true )
    @finance_fee_category = FinanceFeeCategory.find(@feeparticulars.finance_fee_category_id)
    @particulars = FinanceFeeParticulars.paginate(:page => params[:page],:conditions => ["is_deleted = '#{false}' and finance_fee_category_id = '#{@finance_fee_category.id}' "])
    respond_to do |format|
      format.js { render :action => 'master_category_particulars' }
    end
  end
  def master_category_delete
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    @finance_fee_category.update_attributes(:is_deleted => true)
    @finance_fee_category.delete_particulars
    @master_categories = FinanceFeeCategory.paginate(:page => params[:page], :conditions =>["is_deleted = '#{false}' and is_master = '1'"])
    respond_to do |format|
      format.js { render :action => 'master_category_delete' }
    end
  end

  def fees_particulars_new
    @fees_categories = FinanceFeeCategory.find(:all ,:conditions=> ["is_deleted = '#{false}' and is_master = '1'"])
    @student_categories = StudentCategory.find :all
    @finance_fee_particulars = FinanceFeeParticulars.new
    respond_to do |format|
      format.js { render :action => 'fees_particulars_new' }
    end
  end

  def fees_particulars_create
    @finance_fee_particulars = FinanceFeeParticulars.new(params[:finance_fee_particulars])
    unless @finance_fee_particulars.save
      @error = true
    end
    @finance_fee_category = FinanceFeeCategory.find( @finance_fee_particulars .finance_fee_category_id)
    @particulars = FinanceFeeParticulars.paginate(:page => params[:page],:conditions => ["is_deleted = '#{false}' and finance_fee_category_id = '#{@finance_fee_category.id}' "])

  end

  def additional_fees_create_form
    @batches = Batch.active
    @student_categories = StudentCategory.find(:all ,:conditions => ["is_deleted = '#{false}'"])
  end
  
  def additional_fees_create

    batch = params[:additional_fees][:batch_id] unless params[:additional_fees][:batch_id].nil?
    # batch ||=[]
    @batches = Batch.active
    @user = current_user
    @students = Student.find_all_by_batch_id(batch) unless batch.nil?
    @additional_category = FinanceFeeCategory.new(
      :name => params[:additional_fees][:name],
      :description => params[:additional_fees][:description],
      :batch_id => params[:additional_fees][:batch_id]
    )
    
    if @additional_category.save
      @collection_date = FinanceFeeCollection.create(
        :name => @additional_category.name,
        :start_date => params[:additional_fees][:start_date],
        :end_date => params[:additional_fees][:end_date],
        :due_date => params[:additional_fees][:due_date],
        :batch_id => params[:additional_fees][:batch_id],
        :fee_category_id => @additional_category.id
      )
      body = "<p>Fee submission date for "+@additional_category.name+" has been published <br />
                               Fees submitting date starts on<br />
                               Start date :"+@collection_date.start_date.to_s+"<br />"+
        "End date :"+@collection_date.end_date.to_s+"<br /"+
        "Due date :"+@collection_date.due_date.to_s
      subject = "Fees submission date"
      @due_date = @collection_date.due_date.strftime("%Y-%b-%d") +  " 00:00:00"
      unless batch.empty?
        @students.each do |s|
          FinanceFee.create(:student_id => s.id,:fee_collection_id => @collection_date.id)
          Reminder.create(:sender=>@user.id, :recipient=>s.id, :subject=> subject,
            :body => body, :is_read=>false, :is_deleted_by_sender=>false,:is_deleted_by_recipient=>false)
        end
        Event.create(:title=> "Fees Due", :description =>@additional_category.name, :start_date => @due_date, :end_date => @due_date, :is_due => true)
      else
        @batches.each do |b|
          @students = Student.find_all_by_batch_id(b.id)
          @students.each do |s|
            FinanceFee.create(:student_id => s.id,:fee_collection_id => @collection_date.id)
            Reminder.create(:sender=>@user.id, :recipient=>s.student_user, :subject=> subject,
              :body => body, :is_read=>false, :is_deleted_by_sender=>false,:is_deleted_by_recipient=>false)
           end
        end
        Event.create(:title=> "Fees Due", :description =>@additional_category.name, :start_date => @due_date, :end_date => @due_date, :is_due => true)
      end
      flash[:notice] = "Category created, please add Particulars for the category"
      redirect_to(:action => "add_particulars" ,:id => @collection_date.id)
    else
      flash[:notice] = 'Fields with * cannot be empty'
      redirect_to :action => "additional_fees_create_form"
    end
  end

  def additional_fees_edit
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    respond_to do |format|
      format.js { render :action => 'additional_fees_edit' }
    end
  end

  def additional_fees_update
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    @finance_fee_category.update_attributes(params[:finance_fee_category])
    @additional_categories = FinanceFeeCategory.paginate(:page => params[:page], :conditions =>["is_deleted = '#{false}' and is_master = '#{false}'"])
  end

  def additional_fees_delete
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    @finance_fee_category.update_attributes(:is_deleted => true)
    @finance_fee_collection = FinanceFeeCollection.find_by_fee_category_id(params[:id])
    @finance_fee_collection.update_attributes(:is_deleted => true)
    @finance_fee_category.delete_particulars
    redirect_to :action => "additional_fees_list"
  end

  def add_particulars
    @collection_date = FinanceFeeCollection.find(params[:id])
    @additional_category = FinanceFeeCategory.find(@collection_date.fee_category_id)
    @student_categories = StudentCategory.find(:all)
    @finance_fee_particulars = FinanceFeeParticulars.new
    @finance_fee_particulars_list = FinanceFeeParticulars.find(:all,:conditions => ["is_deleted = '#{false}' and finance_fee_category_id = '#{@additional_category.id}'"])
  end

  def add_particulars_new
    @collection_date = FinanceFeeCollection.find(params[:id])
    @additional_category = FinanceFeeCategory.find(@collection_date.fee_category_id)
    @student_categories = StudentCategory.find :all
    @finance_fee_particulars = FinanceFeeParticulars.new
  end

  def add_particulars_create
    @collection_date = FinanceFeeCollection.find(params[:id])
    @additional_category = FinanceFeeCategory.find(@collection_date.fee_category_id)

    @finance_fee_particulars = FinanceFeeParticulars.new(params[:finance_fee_particulars])
    @finance_fee_particulars.finance_fee_category_id = @additional_category.id
    unless @finance_fee_particulars.save
      @error = true
    else
      @finance_fee_particulars_list = FinanceFeeParticulars.find(:all,:conditions => ["is_deleted = '#{false}' and finance_fee_category_id = '#{@additional_category.id}'"])
    end
    
  end

  def student_or_student_category
    @student_categories = StudentCategory.find :all

    select_value = params[:select_value]

    if select_value == "category"
      render :update do |page|
        page.replace_html "student", :partial => "student_category_particulars"
      end
    elsif select_value == "student"
      render :update do |page|
        page.replace_html "student", :partial => "student_admission_particulars"
      end
    end
  end

  def additional_fees_list
    
    @additional_categories = FinanceFeeCategory.paginate(:page => params[:page],:conditions => ["is_deleted = '#{false}' and is_master = '#{false}'"])
     

  end

  def additional_particulars
    @additional_category = FinanceFeeCategory.find(params[:id])
    @particulars = FinanceFeeParticulars.paginate(:page => params[:page],:conditions => ["is_deleted = '#{false}' and finance_fee_category_id = '#{@additional_category.id}' "])
    respond_to do |format|
      format.js { render :action => 'additional_particulars'}
    end
  end

  def add_particulars_edit
    @finance_fee_particulars = FinanceFeeParticulars.find(params[:id])
  end
  
  def add_particulars_update
    @finance_fee_particulars = FinanceFeeParticulars.find(params[:id])
    @finance_fee_particulars.update_attributes(params[:finance_fee_particulars])
    @additional_category = FinanceFeeCategory.find @finance_fee_particulars.finance_fee_category_id
    @particulars = FinanceFeeParticulars.paginate(:page => params[:page],:conditions => ["is_deleted = '#{false}' and finance_fee_category_id = '#{@finance_fee_particulars.finance_fee_category_id}' "])
  end

  def add_particulars_delete
    @finance_fee_particulars = FinanceFeeParticulars.find(params[:id])
    @finance_fee_particulars.update_attributes(:is_deleted => true)
    @additional_category = FinanceFeeCategory.find(@finance_fee_particulars.finance_fee_category_id)
    @particulars = FinanceFeeParticulars.paginate(:page => params[:page],:conditions => ["is_deleted = '#{false}' and finance_fee_category_id = '#{@additional_category.id}' "])

    respond_to do |format|
      format.js { render :action => 'additional_particulars'}
    end
  end

  def fee_collection_batch_update
    @fee_category = FinanceFeeCategory.find(params[:id])
    @batch_ids = @fee_category.batch(&:id)
    unless @batch_ids.nil?
      @batchs = Batch.find_all_by_id @batch_ids
    else
      @batchs = Batch.active
    end
    render :update do |page|
      page.replace_html "batchs" ,:partial => "fee_collection_batchs"
    end
    
  end

  def fee_collection_new
    @fee_categories = FinanceFeeCategory.find(:all , :conditions => ["is_master = '#{1}' and is_deleted = '#{false}'"])
    @finance_fee_collection = FinanceFeeCollection.new
  end

  def fee_collection_create
    @user = current_user
    fee_category = FinanceFeeCategory.find(params[:finance_fee_collection][:fee_category_id])
    batchs =[]
    batchs = params[:fee_collection][:batch_ids]
    subject = "Fees submission date"
       
    batchs.each do |b|
      @finance_fee_collection = FinanceFeeCollection.new(
        :name => params[:finance_fee_collection][:name],
        :start_date => params[:finance_fee_collection][:start_date],
        :end_date => params[:finance_fee_collection][:end_date],
        :due_date => params[:finance_fee_collection][:due_date],
        :fee_category_id => fee_category.id,
        :batch_id => b
      )
      if @finance_fee_collection.save
        @students = Student.find_all_by_batch_id(b)
        @students.each do |s|
          body = "<p><b>Fee submission date for<i>"+fee_category.name+"</i>has been published</b><br /><br/>
                                Start date :"+@finance_fee_collection.start_date.to_s+"<br />"+
            "End date :"+@finance_fee_collection.end_date.to_s+"<br />"+
            "Dude date :"+@finance_fee_collection.due_date.to_s+"<br /><br /><br />"+
            "check your  <a href='../../finance/student_fees_structure/#{s.id}/#{@finance_fee_collection.id}'>Fee structure</a> <br/><br/><br/>
                               regards,<br/>"+@user.full_name.capitalize

          FinanceFee.create(:student_id => s.id,:fee_collection_id => @finance_fee_collection.id)
          Reminder.create(:sender=>@user.id, :recipient=>s.student_user, :subject=> subject,
            :body => body, :is_read=>false, :is_deleted_by_sender=>false,:is_deleted_by_recipient=>false)
       end
          Event.create(:title=> "Fees Due", :description =>fee_category.name, :start_date => @finance_fee_collection.due_date, :end_date => @finance_fee_collection.due_date, :is_due => true)
        
      else
        @error = true
      end
    end
  end


  def fee_collection_view
    @batchs = Batch.active
  end

  def fee_collection_dates_batch
    @batch= Batch.find(params[:id])
    @finance_fee_collections = @batch.fee_collection_dates
    render :update do |page|
      page.replace_html 'fee_collection_dates', :partial => 'fee_collection_dates_batch'
    end
  end

  def fee_collection_edit
    @finance_fee_collection = FinanceFeeCollection.find params[:id]
  end
  
  def fee_collection_update
    @finance_fee_collection = FinanceFeeCollection.find params[:id]
    flash[:notice]="Fee Collection updated successfully" if @finance_fee_collection.update_attributes(params[:fee_collection]) if request.post?
    @finance_fee_collections = FinanceFeeCollection.all(:conditions => ["is_deleted = '#{false}' and batch_id = '#{@finance_fee_collection.batch_id}'"])
  end

  def fee_collection_delete
    @finance_fee_collection = FinanceFeeCollection.find params[:id]
    @finance_fee_collection.update_attributes(:is_deleted => true)
    @finance_fee_collections = FinanceFeeCollection.all(:conditions => ["is_deleted = '#{false}' and batch_id = '#{@finance_fee_collection.batch_id}'"])
  end

  #fees_submission-----------------------------------

  def fees_submission_batch

    @batches = Batch.active
    @dates = []

  end
    
  def update_fees_collection_dates
    
    @batch = Batch.find(params[:batch_id])
    @dates = @batch.fee_collection_dates

    render :update do |page|
      page.replace_html "fees_collection_dates", :partial => "fees_collection_dates"
    end
  end

  def load_fees_submission_batch
    
    @batch   = Batch.find(params[:batch_id])
    @dates   = FinanceFeeCollection.find(:all)
    @date    = FinanceFeeCollection.find(params[:date])
    @student = Student.find(params[:student]) if params[:student]

    @student ||= @batch.students.first
    @prev_student = @student.previous_student
    @next_student = @student.next_student

    @financefee = @student.finance_fee_by_date @date
    @fee_collection = FinanceFeeCollection.find(params[:date])
    @due_date = @fee_collection.due_date
   
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted = false"])
    @fee_particulars = @fee_category.fees(@student)

    render :update do |page|
      page.replace_html "student", :partial => "student_fees_submission"
    end
  end

  def update_ajax

    @batch   = Batch.find(params[:batch_id])
    @dates = FinanceFeeCollection.find(:all)
    @date = FinanceFeeCollection.find(params[:date])
    @student = Student.find(params[:student]) if params[:student]
    @student ||= @batch.students.first
    @prev_student = @student.previous_student
    @next_student = @student.next_student

    total_fees =0

    @financefee = @student.finance_fee_by_date @date
    @fee_collection = FinanceFeeCollection.find(params[:date])
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @fee_category.fees(@student)
    @fee_particulars.each do |p|
      total_fees += p.amount
    end
    unless params[:fine].nil?
      total_fees += params[:fine].to_f
    end
       
    transaction = FinanceTransaction.new
    transaction.title = "Recipit No. F#{@financefee.id}"
    transaction.category = FinanceTransactionCategory.find_by_name("Fee")
    transaction.student_id = params[:student]
    transaction.amount = total_fees
    transaction.fine_included = true  unless params[:fine].nil?
    transaction.finance_fees_id = @financefee.id
    transaction.save

    @financefee.update_attribute(:transaction_id, transaction.id)

    render :update do |page|
      page.replace_html "student", :partial => "student_fees_submission"
      
    end

  end

  def student_fee_receipt_pdf
    @date    = FinanceFeeCollection.find(params[:id2])
    @student = Student.find(params[:id])

    @financefee = @student.finance_fee_by_date @date
    @fee_collection = FinanceFeeCollection.find(params[:id2])
    @due_date = @fee_collection.due_date

    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted = false"])
    @fee_particulars = @fee_category.fees(@student)
    @currency_type = Configuration.find_by_config_key("CurrencyType").config_value
    respond_to do |format|
      format.pdf { render :layout => false }
    end

  end

  def update_fine_ajax
    if request.post?
      @batch   = Batch.find(params[:fine][:batch_id])
      @dates = FinanceFeeCollection.find(:all)
      @date = FinanceFeeCollection.find(params[:fine][:date])
      @student = Student.find(params[:fine][:student]) if params[:fine][:student]
      @student ||= @batch.students.first
      @prev_student = @student.previous_student
      @next_student = @student.next_student
      @fine = (params[:fine][:fee])
      @financefee = @student.finance_fee_by_date @date
      @fee_collection = FinanceFeeCollection.find(params[:fine][:date])
      @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
      @fee_particulars = @fee_category.fees(@student)
      @due_date = @fee_collection.due_date


      render :update do |page|
        page.replace_html "student", :partial => "student_fees_submission", :with => @fine

      end
    end
  end

  def search_logic                 #student search (fees submission)
    query = params[:query]
    @students_result = Student.first_name_like query unless query == ""
    render :layout => false
  end

  def fees_student_dates
    @student = Student.find(params[:id])
    @dates = @student.batch.fee_collection_dates
  end

  def fees_submission_student
    
    @student = Student.find(params[:id])
    @date = FinanceFeeCollection.find(params[:date])
    @financefee = @student.finance_fee_by_date(@date)
    @fee_collection = FinanceFeeCollection.find(params[:date])
    @due_date = @fee_collection.due_date
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @fee_category.fees(@student)

    render :update do |page|
      page.replace_html "fee_submission", :partial => "fees_submission_form"
    end

  end

  def update_student_fine_ajax

    @student = Student.find(params[:fine][:student])
    @fine = (params[:fine][:fee])
    @date = FinanceFeeCollection.find(params[:fine][:date])
    @financefee = @student.finance_fee_by_date(@date)
    @fee_collection = FinanceFeeCollection.find(params[:fine][:date])
    @due_date = @fee_collection.due_date
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @fee_category.fees(@student)

    render :update do |page|
      page.replace_html "fee_submission", :partial => "fees_submission_form"
    end

  end

  def fees_submission_save

    @student = Student.find(params[:student])
    @date = FinanceFeeCollection.find(params[:date])
    @financefee = @date.fee_transactions(@student.id)
    @fee_collection = FinanceFeeCollection.find(params[:date])
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @fee_category.fees(@student)
    total_fees = 0
    @fee_particulars.each do |p|
      total_fees += p.amount
    end
    unless params[:fine].nil?
      total_fees += params[:fine].to_f
    end
  
    if request.post?
      transaction = FinanceTransaction.new
      transaction.title = "Recipit No. F#{@financefee.id}"
      transaction.category = FinanceTransactionCategory.find_by_name("Fee")
      transaction.student_id = params[:student]
      transaction.finance_fees_id = @financefee.id
      transaction.fine_included = true  unless params[:fine].nil?
      transaction.amount = total_fees
      transaction.save
      @financefee.update_attribute(:transaction_id, transaction.id)
    end
    flash[:notice] = 'Fees Paid'
    redirect_to  :action => "fees_student_search"
  end


  #fees structure ----------------------
  
  def fees_student_structure_search_logic # student search fees structure
    query = params[:query]
    @students_result = Student.first_name_like query unless query == ""
    render :layout => false
  end

  def fees_structure_dates
    @student = Student.find(params[:id])
    @dates = @student.batch.fee_collection_dates
  end

  def fees_structure_for_student
    @student = Student.find(params[:id])
    @fee_collection = FinanceFeeCollection.find params[:date]
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @fee_category.fees(@student)
    
    render :update do |page|
      page.replace_html "fees_structure" , :partial => "fees_structure"
    end
  end

  def student_fees_structure
    @student = Student.find(params[:id])
    @fee_collection = FinanceFeeCollection.find params[:id2]
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @fee_category.fees(@student)
  end
  

  #fees defaulters-----------------------

  def fees_defaulters
    @batchs = Batch.active
    @dates = []
  end

  def update_fees_collection_dates_defaulters
    @batch  = Batch.find(params[:batch_id])
    @dates = @batch.fee_collection_dates

    render :update do |page|
      page.replace_html "fees_collection_dates", :partial => "fees_collection_dates_defaulters"
    end
  end

  def fees_defaulters_students
    @batch   = Batch.find(params[:batch_id])
    @date = FinanceFeeCollection.find(params[:date])
    @students = @batch.all_students

    render :update do |page|
      page.replace_html "student", :partial => "student_defaulters"
    end
  end

  def fee_defaulters_pdf
    @batch   = Batch.find(params[:batch_id])
    @date = FinanceFeeCollection.find(params[:date])
    @students = @batch.all_students
    @currency_type = Configuration.find_by_config_key("CurrencyType").config_value
    respond_to do |format|
      format.pdf { render :layout => false }
    end
  end

  def pay_fees_defaulters
    @fine = params[:fine].to_f unless params[:fine].nil?
    @student = Student.find(params[:id])
    @date = FinanceFeeCollection.find(params[:date])
    @financefee = @date.fee_transactions(@student.id)
    @fee_collection = FinanceFeeCollection.find(params[:date])
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @fee_category.fees(@student)

    total_fees = 0
    @fee_particulars.each do |p|
      total_fees += p.amount
    end
    total_fees += @fine unless @fine.nil?

    if request.post?

      transaction = FinanceTransaction.new
      transaction.title = "Recipit No. F#{@financefee.id}"
      transaction.category = FinanceTransactionCategory.find_by_name("Fee")
      transaction.student_id = params[:student]
      transaction.finance_fees_id = @financefee.id
      transaction.amount = total_fees
      transaction.fine_included = true  unless @fine.nil?
      transaction.save
      @financefee.update_attribute(:transaction_id, transaction.id)

      flash[:notice] = "Fees Paid"
      redirect_to  :action => "fees_defaulters"
    
    end
  end

  def update_defaulters_fine_ajax
    @student = Student.find(params[:fine][:student])
    @date = FinanceFeeCollection.find(params[:fine][:date])
    @financefee = @date.fee_transactions(@student.id)
    @fee_collection = FinanceFeeCollection.find(params[:fine][:date])
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @fee_category.fees(@student)
    @fine = params[:fine][:fee].to_f

    total_fees = 0
    @fee_particulars.each do |p|
      total_fees += p.amount
    end
    total_fees += @fine unless @fine.nil?
    redirect_to  :action => "pay_fees_defaulters", :id=> @student.id, :date=> @date.id, :fine => @fine
  end

  def compare_report
    
  end

  def report_compare
    @hr = Configuration.find_by_config_value("HR")
    @start_date = (params[:start_date]).to_date
    @end_date = (params[:end_date]).to_date
    @start_date2 = (params[:start_date2]).to_date
    @end_date2 = (params[:end_date2]).to_date
    @transactions = FinanceTransaction.find(:all,
      :order => 'created_at desc', :conditions => ["created_at >= '#{@start_date}' and created_at <= '#{@end_date}'"])
    @transactions2 = FinanceTransaction.find(:all,
      :order => 'created_at desc', :conditions => ["created_at >= '#{@start_date2}' and created_at <= '#{@end_date2}'"])
    @other_transactions = FinanceTransaction.find(:all, :conditions => ["created_at >= '#{@start_date}' and created_at <= '#{@end_date}'and category_id !='#{3}' and category_id !='#{2}'and category_id !='#{1}'"],
      :order => 'created_at')
    #    @other_transactions = FinanceTransaction.report(@start_date,@end_date,params[:page])
    @other_transactions2 = FinanceTransaction.find(:all, :conditions => ["created_at >= '#{@start_date2}' and created_at <= '#{@end_date2}'and category_id !='#{3}' and category_id !='#{2}'and category_id !='#{1}'"],
      :order => 'created_at')
    #    @transactions_fees = FinanceTransaction.total_fees(@start_date,@end_date)
    @transactions_fees2 = FinanceTransaction.total_fees(@start_date2,@end_date2)
    employees = Employee.find(:all)
    @salary = Employee.total_employees_salary(employees, @start_date, @end_date)
    @salary2 = Employee.total_employees_salary(employees, @start_date2, @end_date2)
    @donations_total = FinanceTransaction.donations_triggers(@start_date,@end_date)
    @donations_total2 = FinanceTransaction.donations_triggers(@start_date2,@end_date2)
    @batchs = Batch.find(:all)
    @grand_total = FinanceTransaction.grand_total(@start_date,@end_date)
    @grand_total2 = FinanceTransaction.grand_total(@start_date2,@end_date2)
    @graph = open_flash_chart_object(960, 500, "graph_for_compare_monthly_report?start_date=#{@start_date}&end_date=#{@end_date}&start_date2=#{@start_date2}&end_date2=#{@end_date2}")
  end
 
  def month_date
    @start_date = params[:start]
    @end_date  = params[:end]
  end



  #reports pdf---------------------------

  def pdf_fee_structure
    @student = Student.find(params[:id])
    @institution_name = Configuration.find_by_config_key("InstitutionName")
    @institution_address = Configuration.find_by_config_key("InstitutionAddress")
    @institution_phone_no = Configuration.find_by_config_key("InstitutionPhoneNo")
    @currency_type = Configuration.find_by_config_key("CurrencyType").config_value
    @fee_collection = FinanceFeeCollection.find params[:id2]
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @fee_category.fees(@student)
    @total = @student.total_fees(@fee_particulars)
    respond_to do |format|
      format.pdf { render :layout => false }
    end
  end

  #graph------------------------------------
 

  def graph_for_update_monthly_report
    
    start_date = (params[:start_date]).to_date
    end_date = (params[:end_date]).to_date
    employees = Employee.find(:all)
    
    hr = Configuration.find_by_config_value("HR")
    donations_total = FinanceTransaction.donations_triggers(start_date,end_date)
    fees = FinanceTransaction.total_fees(start_date,end_date)
    other_transactions = FinanceTransaction.find(:all,
      :conditions => ["created_at >= '#{start_date}' and created_at <= '#{end_date}'and category_id !='#{3}' and category_id !='#{2}'and category_id !='#{1}'"])


    x_labels = []
    data = []
    largest_value =0
    
    unless hr.nil?
      salary = Employee.total_employees_salary(employees,start_date,end_date)
      unless salary <= 0
        x_labels << "Salary"
        data << salary-(salary*2)
        largest_value = salary if largest_value < salary
      end
    end
    unless donations_total <= 0
      x_labels << "Donations"
      data << donations_total
      largest_value = donations_total if largest_value < donations_total
    end

    unless fees <= 0
      x_labels << "Fees"
      data << fees
      largest_value = fees if largest_value < fees
    end
    other_transactions.each do |trans|
      x_labels << trans.title
      if trans.category.is_income?
        data << trans.amount
      else
        data << ("-"+trans.amount.to_s).to_i
      end
      largest_value = trans.amount if largest_value < trans.amount
    end

    largest_value += 500

    bargraph = BarFilled.new()
    bargraph.width = 1;
    bargraph.colour = '#bb0000';
    bargraph.dot_size = 3;
    bargraph.text = "Amount"
    bargraph.values = data

    x_axis = XAxis.new
    x_axis.labels = x_labels

    y_axis = YAxis.new
    y_axis.set_range(largest_value-(largest_value*2),largest_value,largest_value/5)

    title = Title.new("Finance Transaction")

    x_legend = XLegend.new("Examination name")
    x_legend.set_style('{font-size: 14px; color: #778877}')

    y_legend = YLegend.new("Marks")
    y_legend.set_style('{font-size: 14px; color: #770077}')

    chart = OpenFlashChart.new
    chart.set_title(title)
    chart.set_x_legend = x_legend
    chart.set_y_legend = y_legend
    chart.y_axis = y_axis
    chart.x_axis = x_axis

    chart.add_element(bargraph)


    render :text => chart.render
 
  end
  def graph_for_compare_monthly_report

    start_date = (params[:start_date]).to_date
    end_date = (params[:end_date]).to_date
    start_date2 = (params[:start_date2]).to_date
    end_date2 = (params[:end_date2]).to_date
    employees = Employee.find(:all)

    hr = Configuration.find_by_config_value("HR")
    donations_total = FinanceTransaction.donations_triggers(start_date,end_date)
    donations_total2 = FinanceTransaction.donations_triggers(start_date2,end_date2)
    fees = FinanceTransaction.total_fees(start_date,end_date)
    fees2 = FinanceTransaction.total_fees(start_date2,end_date2)
    other_transactions = FinanceTransaction.find(:all,
      :conditions => ["created_at >= '#{start_date}' and created_at <= '#{end_date}'and category_id !='#{3}' and category_id !='#{2}'and category_id !='#{1}'"])
    other_transactions2 = FinanceTransaction.find(:all,
      :conditions => ["created_at >= '#{start_date2}' and created_at <= '#{end_date2}'and category_id !='#{3}' and category_id !='#{2}'and category_id !='#{1}'"])


    x_labels = []
    data = []
    data2 = []
    largest_value =0

    unless hr.nil?
      salary = Employee.total_employees_salary(employees,start_date,end_date)
      salary2 = Employee.total_employees_salary(employees,start_date2,end_date2)
      unless salary <= 0 and salary2 <= 0
        x_labels << "Salary"
        data << salary-(salary*2)
        data2 << salary2-(salary2*2)
        largest_value = salary if largest_value < salary
        largest_value = salary2 if largest_value < salary2
      end
    end
    unless donations_total <= 0 and donations_total2 <= 0
      x_labels << "Donations"
      data << donations_total
      data2 << donations_total2
      largest_value = donations_total if largest_value < donations_total
      largest_value = donations_total2 if largest_value < donations_total2
    end

    unless fees <= 0 and fees2 <= 0
      x_labels << "Fees"
      data << fees
      data2 << fees2
      largest_value = fees if largest_value < fees
      largest_value = fees2 if largest_value < fees2
    end
    other = 0
    other_transactions.each do |trans|
      
      if trans.category.is_income?
        other += trans.amount
      else
        other -= trans.amount
      end
    end
    x_labels << "other"
    data << other
    largest_value = other if largest_value < other
    other2 = 0
    other_transactions2.each do |trans2|
      if trans2.category.is_income?
        other2 += trans2.amount
      else
        other2 -= trans2.amount
      end
    end
    data2 << other2
    largest_value = other2 if largest_value < other2

    largest_value += 500

    bargraph = BarFilled.new()
    bargraph.width = 1;
    bargraph.colour = '#bb0000';
    bargraph.dot_size = 3;
    bargraph.text = "For the period #{start_date}-#{end_date}"
    bargraph.values = data
    bargraph2 = BarFilled.new()
    bargraph2.width = 1;
    bargraph2.colour = '#000000';
    bargraph2.dot_size = 3;
    bargraph2.text = "For the period #{start_date2}-#{end_date2}"
    bargraph2.values = data2

    x_axis = XAxis.new
    x_axis.labels = x_labels

    y_axis = YAxis.new
    y_axis.set_range(largest_value-(largest_value*2),largest_value,largest_value/5)

    title = Title.new("Finance Transaction")

    x_legend = XLegend.new("Examination name")
    x_legend.set_style('{font-size: 14px; color: #778877}')

    y_legend = YLegend.new("Marks")
    y_legend.set_style('{font-size: 14px; color: #770077}')

    chart = OpenFlashChart.new
    chart.set_title(title)
    chart.set_x_legend = x_legend
    chart.set_y_legend = y_legend
    chart.y_axis = y_axis
    chart.x_axis = x_axis

    chart.add_element(bargraph)
    chart.add_element(bargraph2)


    render :text => chart.render

  end
  
  #ddnt complete this graph!

  def graph_for_transaction_comparison

    start_date = (params[:start_date]).to_date
    end_date = (params[:end_date]).to_date
    employees = Employee.find(:all)

    hr = Configuration.find_by_config_value("HR")
    donations_total = FinanceTransaction.donations_triggers(start_date,end_date)
    fees = FinanceTransaction.total_fees(start_date,end_date)
    other_transactions = FinanceTransaction.find(:all,
      :conditions => ["created_at >= '#{start_date}' and created_at <= '#{end_date}'and category_id !='#{3}' and category_id !='#{2}'and category_id !='#{1}'"])


    x_labels = []
    data1 = []
    data2 = []
    
    largest_value =0

    unless hr.nil?
      salary = Employee.total_employees_salary(employees,start_date,end_date)
    end
    unless salary <= 0
      x_labels << "Salary"
      data << salary-(salary*2)
      largest_value = salary if largest_value < salary
    end
    unless donations_total <= 0
      x_labels << "Donations"
      data << donations_total
      largest_value = donations_total if largest_value < donations_total
    end

    unless fees <= 0
      x_labels << "Fees"
      data << fees
      largest_value = fees if largest_value < fees
    end
    other_transactions.each do |trans|
      x_labels << trans.title
      if trans.category.is_income?
        data << trans.amount
      else
        data << ("-"+trans.amount.to_s).to_i
      end
      largest_value = trans.amount if largest_value < trans.amount
    end

    largest_value += 500

    bargraph = BarFilled.new()
    bargraph.width = 1;
    bargraph.colour = '#bb0000';
    bargraph.dot_size = 3;
    bargraph.text = "Amount"
    bargraph.values = data

    x_axis = XAxis.new
    x_axis.labels = x_labels

    y_axis = YAxis.new
    y_axis.set_range(largest_value-(largest_value*2),largest_value,largest_value/5)

    title = Title.new("Finance Transaction")

    x_legend = XLegend.new("Examination name")
    x_legend.set_style('{font-size: 14px; color: #778877}')

    y_legend = YLegend.new("Marks")
    y_legend.set_style('{font-size: 14px; color: #770077}')

    chart = OpenFlashChart.new
    chart.set_title(title)
    chart.set_x_legend = x_legend
    chart.set_y_legend = y_legend
    chart.y_axis = y_axis
    chart.x_axis = x_axis

    chart.add_element(bargraph)


    render :text => chart.render
 
   
  end

end