class RenameRoomateIdToRoommateId < ActiveRecord::Migration

  def up
    rename_column :people, :roomate_id1, :roommate_id1
    rename_column :people, :roomate_id2, :roommate_id2
  end

  def down
    rename_column :people, :roommate_id1, :roomate_id1
    rename_column :people, :roommate_id2, :roomate_id2
  end

end
