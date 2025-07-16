class CreateAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :assignments do |t|
      t.string :role
      t.boolean :active
      t.integer :place
      t.boolean :ci
      t.string :status
      t.integer :ccs
      t.integer :vcs
      t.integer :ct
      t.integer :vt
      t.integer :majtes
      t.integer :tietes
      t.integer :ccs_m
      t.integer :ccs_k
      t.integer :vcs_a
      t.integer :vcs_c
      t.integer :vcs_t
      t.integer :vcs_p

      t.timestamps
    end
  end
end
