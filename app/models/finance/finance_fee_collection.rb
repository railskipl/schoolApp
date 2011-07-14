class FinanceFeeCollection < ActiveRecord::Base
  belongs_to :batch
  has_many :finance_fees
  belongs_to :fee_category,:class_name => "FinanceFeeCategory"

  validates_presence_of :name,:start_date,:fee_category_id,:end_date,:due_date

  def full_name
    "#{name} - #{start_date.to_s}"
  end

  def fee_transactions(student_id)
    FinanceFee.find_by_fee_collection_id_and_student_id(self.id,student_id)
  end

  def check_transaction(transactions)
    transactions.finance_fees_id.nil? ? false : true
   
  end

  def self.shorten_string(string, count)
    if string.length >= count
      shortened = string[0, count]
      splitted = shortened.split(/\s/)
      words = splitted.length
      splitted[0, words-1].join(" ") + ' ...'
    else
      string
    end
  end

  def check_fee_category
    finance_fees = FinanceFee.find_all_by_fee_collection_id(self.id)
    flag = 0
    finance_fees.each do |f|
      f.transaction_id.nil? ? flag = 1 : flag = 0
    end
    flag == 1 ? true : false
  end
end

# == Schema Information
#
# Table name: finance_fee_collections
#
#  id              :integer(4)      not null, primary key
#  name            :string(255)
#  start_date      :date
#  end_date        :date
#  due_date        :date
#  fee_category_id :integer(4)
#  batch_id        :integer(4)
#  is_deleted      :boolean(1)      default(FALSE), not null
#

