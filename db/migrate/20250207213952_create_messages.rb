class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.date :dod
      t.string :tod
      t.string :dow
      t.string :title
      t.string :descriptor

      t.timestamps
    end
  end
end
