class AddCurAssignIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :cur_assign_id, :integer
  end
end
