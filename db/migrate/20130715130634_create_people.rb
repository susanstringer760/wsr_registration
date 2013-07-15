class CreatePeople < ActiveRecord::Migration
  def change
    create_table :people do |t|
      t.string :last_name
      t.string :first_name
      t.string :address
      t.string :city
      t.string :zip
      t.string :email
      t.string :phone
      t.string :payment_type
      t.string :payment_status
      t.string :registration_status
      t.float :paid_amount, :default=>0.0
      t.float :scholarship_amount, :default=>0.0
      t.float :scholarship_donation, :default=>0.0
      t.float :balance_due, :default=>0.0
      t.float :total_due, :default=>0.0
      t.integer :occupancy
      t.integer :check_num
      t.integer :can_drive_num 
      t.integer :wait_list_num
      t.integer :roomate_id1
      t.integer :roomate_id2
      t.boolean :needs_ride
      t.date :paid_date
      t.date :registration_date
      t.date :due_date

      t.timestamps
    end
  end
end

