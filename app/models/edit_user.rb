#class EditUser < ActiveRecord::Base
class EditUser < ApplicationRecord
    belongs_to :edit
    belongs_to :user
  
  end