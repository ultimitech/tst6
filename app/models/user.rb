#class User < ActiveRecord::Base
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable, 
         :recoverable, :rememberable, :trackable, :validatable

  #attr_accessible :email, :password, :password_confirmation, :remember_me, :username

  has_many :assignments
  has_many :translations, through: :assignments

  #has_many :contribution
  #has_many :edits, through: :contributions

  belongs_to :cur_assign, class_name: "Assignment", foreign_key: "cur_assign_id"

  #VALID_USERNAME_REGEX = /[a-z]{6}/i
  #validates :username, presence: true, uniqueness: { case_sensitive: false }, length: { minimum: 6, maximum: 6}, format: { with: VALID_USERNAME_REGEX }
  #validates :username, presence: true, uniqueness: { case_sensitive: false }, length: { minimum: 1, maximum: 16}
 
  #VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  #validates :email, presence: true, length: {maximum: 105}, uniqueness: { case_sensitive: false }, format: { with: VALID_EMAIL_REGEX }
  #
  #has_secure_password
 
  protected
  def confirmation_required?
    false
  end

end