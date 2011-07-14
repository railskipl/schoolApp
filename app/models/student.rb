class Student < ActiveRecord::Base
  belongs_to :country
  belongs_to :batch
  belongs_to :student_category
  belongs_to :nationality, :class_name => 'Country'
  has_one    :immediate_contact
  has_one    :student_previous_data
  has_many   :student_previous_subject_mark
  has_many   :guardians, :foreign_key => 'ward_id', :dependent => :destroy
  has_many   :finance_transactions
  has_many   :fee_category ,:class_name => "FinanceFeeCategory"

  has_and_belongs_to_many :graduated_batches, :class_name => 'Batch', :join_table => 'batch_students'

  named_scope :active, :conditions => { :is_active => true }

  validates_presence_of :admission_no, :admission_date, :first_name, :last_name, :batch_id, :date_of_birth, :student_category
  validates_uniqueness_of :admission_no
  validates_presence_of :gender
  
  has_attached_file :stuphoto, 
                    :styles => { :thumb => "125x125" },
                     :storage => :s3, :s3_credentials => "#{RAILS_ROOT}/config/s3.yml",
                    :path => "public/attachments/student/:id/:style/:basename.:extension",
                    :convert_options => {
                          :thumb => "-background '#FFFFFF' -compose Copy -gravity center -extent 125x125"
                      }

  after_save :create_user_account

  def validate
    errors.add(:date_of_birth, "can't be a future date.") if self.date_of_birth >= Date.today \
      unless self.date_of_birth.nil?
    errors.add(:gender, 'attribute is invalid.') unless ['m', 'f'].include? self.gender.downcase \
      unless self.gender.nil?
    errors.add(:admission_no, 'can\'t be zero') if self.admission_no=='0'
      
  end

  def first_and_last_name
    "#{first_name} #{last_name}"
  end

  def full_name
    "#{first_name} #{middle_name} #{last_name}"
  end

  def gender_as_text
    return 'Male' if gender.downcase == 'm'
    return 'Female' if gender.downcase == 'f'
    nil
  end

  def user
    User.find_by_username self.admission_no
  end

  def all_batches
    self.graduated_batches + self.batch.to_a
  end

  def immediate_contact
    Guardian.find(self.immediate_contact_id) unless self.immediate_contact_id.nil?
  end

  def image_file=(input_data)
    return if input_data.blank?
    self.photo_filename     = input_data.original_filename
    self.photo_content_type = input_data.content_type.chomp
    self.photo_data         = input_data.read
  end

  def next_student
    next_st = self.batch.students.first(:conditions => "id > #{self.id}", :order => "id ASC")
    next_st ||= batch.students.first(:order => "id ASC")
  end

  def previous_student
    prev_st = self.batch.students.first(:conditions => "id < #{self.id}", :order => "admission_no DESC")
    prev_st ||= batch.students.first(:order => "id DESC")
    prev_st ||= self.batch.students.first(:order => "id DESC")
  end

  def finance_fee_by_date(date)
    FinanceFee.find_by_fee_collection_id_and_student_id(date.id,self.id)
  end

  def check_fees_paid(date)
    category = FinanceFeeCategory.find(date.fee_category_id)
    particulars = category.fees(self)

    financefee = date.fee_transactions(self.id)
    unless particulars.nil?
      return financefee.check_transaction_done unless financefee.nil?
      
    else
      return false
    end
  end

  def self.next_admission_no
    '' #stub for logic to be added later.
  end
  
  def get_fee_strucure_elements(date)
    elements = FinanceFeeStructureElement.get_student_fee_components(self,date)
    elements[:all] + elements[:by_batch] + elements[:by_category] + elements[:by_batch_and_category]
  end

  def total_fees(particulars)
    total = 0
    particulars.each do |fee|
      total += fee.amount
    end
    total
  end

  def archive_student(status)
    self.update_attributes(:is_active => false, :status_description => status)
    student_attributes = self.attributes
    student_attributes["former_id"]= self.id
    student_attributes.delete "id"
    if archived_student = ArchivedStudent.create(student_attributes)
      guardian = self.guardians
      user = User.find_by_username(self.admission_no)
      unless user.nil?
        user.delete
      end
      self.delete
      guardian.each do |g|
        g.archive_guardian(archived_student.id)
      end
      #
      student_exam_scores = ExamScore.find_all_by_student_id(self.id)
      student_exam_scores.each do |s|
        exam_score_attributes = s.attributes
        exam_score_attributes.delete "id"
        exam_score_attributes.delete "student_id"
        exam_score_attributes["student_id"]= archived_student.id
        ArchivedExamScore.create(exam_score_attributes)
        s.delete
      end
      #
      student_homework_scores = homeworkScore.find_all_by_student_id(self.id)
      student_homework_scores.each do |s|
      homework_score_attributes = s.attributes
      homework_score_attributes.delete "id"
      homework_score_attributes.delete "student_id"
      homework_score_attributes["student_id"]= archived_student.id
      ArchivedhomeworkScore.create(homework_score_attributes)
      s.delete
      end
      #
      
    end
 
  end
  
  def student_user
    User.find_by_username(self.admission_no).id
  end

  private
  def create_user_account
    user = User.new do |u|
      u.first_name, u.last_name, u.username = first_name, last_name, admission_no.to_s
      u.password = "#{admission_no.to_s}123"
      u.role = 'Student'
      u.email = ( email == '' or User.find_by_email(email) ) ? "info#{admission_no.to_s}@kunalinfotech.net" : email
    end
    user.save
  end

end
# == Schema Information
#
# Table name: students
#
#  id                   :integer(4)      not null, primary key
#  admission_no         :string(255)
#  class_roll_no        :string(255)
#  admission_date       :date
#  first_name           :string(255)
#  middle_name          :string(255)
#  last_name            :string(255)
#  batch_id             :integer(4)
#  date_of_birth        :date
#  gender               :string(255)
#  blood_group          :string(255)
#  birth_place          :string(255)
#  nationality_id       :integer(4)
#  language             :string(255)
#  religion             :string(255)
#  student_category_id  :integer(4)
#  address_line1        :string(255)
#  address_line2        :string(255)
#  city                 :string(255)
#  state                :string(255)
#  pin_code             :string(255)
#  country_id           :integer(4)
#  phone1               :string(255)
#  phone2               :string(255)
#  email                :string(255)
#  immediate_contact_id :integer(4)
#  is_sms_enabled       :boolean(1)      default(TRUE)
#  photo_filename       :string(255)
#  photo_content_type   :string(255)
#  photo_data           :binary(16777215
#  status_description   :string(255)
#  is_active            :boolean(1)      default(TRUE)
#  is_deleted           :boolean(1)      default(FALSE)
#  created_at           :datetime
#  updated_at           :datetime
#

