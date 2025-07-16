#class Lookup < ActiveRecord::Base
class Lookup < ApplicationRecord
    belongs_to :translation
  end