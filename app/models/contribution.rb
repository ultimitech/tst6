#class Contribution < ActiveRecord::Base
class Contribution < ApplicationRecord
    belongs_to :assignment
    belongs_to :edit
    belongs_to :base_edit, :class_name => "Edit"
  
    def self.cutoff
      600 #in seconds, #600seconds == 10 minutes
    end
  
    def contribution_text
      "#{kind}-#{edit.id}-#{edit.content}"
    end
  end