class AddMealPreferenceToPeople < ActiveRecord::Migration
  def change
    add_column :people, :email_preference, :string, :default=>'none'
  end
end
