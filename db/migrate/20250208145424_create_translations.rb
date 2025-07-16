class CreateTranslations < ActiveRecord::Migration[8.0]
  def change
    create_table :translations do |t|
      t.string :lan
      t.string :tran_title
      t.string :descrip
      t.integer :blkc
      t.integer :subc
      t.integer :senc
      t.string :xcrip
      t.boolean :li
      t.date :pubdate
      t.string :version
      t.references :message, null: false, foreign_key: true

      t.timestamps
    end
  end
end
