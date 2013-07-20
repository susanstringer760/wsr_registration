# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130720040929) do

  create_table "notes", :force => true do |t|
    t.datetime "date_time"
    t.text     "content"
    t.string   "note_type"
    t.integer  "person_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "people", :force => true do |t|
    t.string   "last_name"
    t.string   "first_name"
    t.string   "address"
    t.string   "city"
    t.string   "zip"
    t.string   "email"
    t.string   "phone"
    t.string   "payment_type"
    t.string   "payment_status"
    t.string   "registration_status"
    t.float    "paid_amount"
    t.float    "scholarship_amount"
    t.float    "scholarship_donation"
    t.float    "balance_due"
    t.integer  "occupancy"
    t.integer  "check_num"
    t.integer  "can_drive_num"
    t.integer  "wait_list_num"
    t.integer  "roommate_id1"
    t.integer  "roommate_id2"
    t.boolean  "needs_ride"
    t.date     "paid_date"
    t.date     "registration_date"
    t.date     "due_date"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.float    "total_due",            :default => 0.0
  end

end
