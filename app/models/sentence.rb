#class Sentence < ActiveRecord::Base
class Sentence < ApplicationRecord
    belongs_to :translation
    has_many :edits
    validates :blk, numericality: { only_integer: true }
    validates :rsub, numericality: { only_integer: true }
    validates :sen, numericality: { only_integer: true }
    validates :typ, presence: true, length: { minimum: 1, maximum: 1 }
    validates :translation_id, presence: true
  
    attr_accessor :search_term #virtual attribute: not persisted
  
    def sentence_text
      "#{blk}.#{sub}.#{rsub}.#{sen}.#{rsen}.#{typ}"
    end
  
    #searchable do
    #  text :typ
    #  #text :edits do
    #  #  edits.map { |edit| edit.content } 
    #  #end
    #end
  end