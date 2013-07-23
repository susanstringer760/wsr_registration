class RemoveOriNotesFromPeople < ActiveRecord::Migration
  def up
    remove_column :people, :ori_notes
  end

  def down
    add_column :people, :ori_notes, :text
  end
end
