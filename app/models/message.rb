#class Message < ActiveRecord::Base
class Message < ApplicationRecord
  has_many :translations
  # before_save { self.tod = tod.downcase, self.dow = dow.downcase } handled in template - only submits correct form
  validates :dod, presence: true
  validates :tod, presence: true, inclusion: { in: %w(s b x y z),
    message: "%{value} is not a valid time of day. Use one of: s b x y z" }
  validates :dow, presence: true, inclusion: { in: %w(su mo tu we th fr sa),
    message: "%{value} is not a valid day of week. Use one of: su mo tu we th fr sa" }
  validates :title, presence: true, length: { minimum: 1, maximum: 64 }

  def message_text
    "#{dod}#{tod} #{title}"
  end
end