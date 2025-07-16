#class TextExport < ActiveRecord::Base
class TextExport
    include ActiveModel::Model
    attr_accessor :blk_separators, :sub_separators, :sen_separators, :format_emphases, :format_scripture_sentences, :format_conversation_sentences, :format_poetry_sentences, :show_blk_numbers, :show_sub_numbers, :show_rsub_numbers, :show_sen_numbers, :show_rsen_numbers, :show_typ_characters, :export_mode, :export_format
  end