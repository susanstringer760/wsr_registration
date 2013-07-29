class ChangeEmailPreferenceToMealPreferenceInPeople < ActiveRecord::Migration

def up
    rename_column :people, :email_preference, :meal_preference
  end

  def down
    rename_column :people, :meal_preference, :email_preference
  end

end
