#class Edit < ActiveRecord::Base
class Edit < ApplicationRecord
    has_many :contributions
    has_many :assignments, through: :contributions
  
    belongs_to :sentence
  
    validates :content, length: { minimum: 0, maximum: 1024 }
    # validates :edit_id, presence: true
  
    def edit_text
      "#{sentence.blk}.#{sentence.sub}.#{sentence.rsub}.#{sentence.sen}.#{sentence.rsen}.#{sentence.typ} #{content}"
    end
  
    def vote_count
      contributions.where(kind: 'V').count if contributions
    end
  
    #def voted_for
    #  contributions.joins(assignment: :user).where(contributions: {kind: 'V'}, users: {username: current_user.username})
    #end
  end