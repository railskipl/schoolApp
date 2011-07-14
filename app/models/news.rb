class News < ActiveRecord::Base
  belongs_to :author, :class_name => 'User'
  has_many :comments, :class_name => 'NewsComment'
  
  validates_presence_of :title, :content

  default_scope :order => 'created_at DESC'

  cattr_reader :per_page

  @@per_page = 12
end
# == Schema Information
#
# Table name: news
#
#  id         :integer(4)      not null, primary key
#  title      :string(255)
#  content    :text
#  author_id  :integer(4)
#  created_at :datetime
#  updated_at :datetime
#

