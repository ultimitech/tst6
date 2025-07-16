#class Translation < ActiveRecord::Base
class Translation < ApplicationRecord
  has_many :assignments
  has_many :users, through: :assignments

  belongs_to :message

  has_many :sentences
  has_many :lookups

  belongs_to :eng_tran, class_name: "Translation", foreign_key: "eng_tran_id"

  validates :lan, presence: true, length: { minimum: 3, maximum: 4 }
  validates :tran_title, presence: true, length: { minimum: 3, maximum: 70 }
  validates :descrip, presence: false, length: { minimum: 0, maximum: 500 }
  validates :blkc, numericality: { only_integer: true }
  validates :subc, numericality: { only_integer: true }
  validates :senc, numericality: { only_integer: true }
  validates :xcrip, presence: true
  validates :message_id, presence: true

  attr_accessor :file_name

=begin
  def translator

  end

  def translator=(userid)
    Assignment.new(user_id: userid)
  end

  def translator_kind

  end

  def translator_kind=(kind)
    if(kind == 'MT
  end
=end

  def translation_text
    "[#{lan} #{blkc}.#{subc}.#{senc}.#{xcrip}] #{message.dod}#{message.tod} #{message.title} (#{version})"
  end
  
  def status_text
    "#{message.dod}#{message.tod} #{message.title}"
  end
  
  def eng_tran_text
    if eng_tran
      "[#{eng_tran.lan} #{eng_tran.blkc}.#{eng_tran.subc}.#{eng_tran.senc}.#{eng_tran.xcrip}]"
    else
      "N/A"
    end
  end
end