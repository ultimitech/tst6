#class DashExport < ActiveRecord::Base
class DashExport
    include ActiveModel::Model
    attr_accessor :blk_separators, :sub_separators, :sen_separators, :exclude_scripture_sentences, :exclude_poetry_sentences, :show_blk_numbers, :show_sub_numbers, :show_rsub_numbers, :show_sen_numbers, :show_rsen_numbers, :show_typ_characters, :export_mode, :export_format
  end