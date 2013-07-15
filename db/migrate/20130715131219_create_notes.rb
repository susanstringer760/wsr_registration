class CreateNotes < ActiveRecord::Migration

  def change
    create_table :notes do |t|
      t.datetime :date_time
      t.text :content
      t.string :note_type
      t.integer :person_id

      t.timestamps
    end
  end
end
