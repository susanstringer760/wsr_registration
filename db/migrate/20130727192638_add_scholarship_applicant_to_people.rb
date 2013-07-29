class AddScholarshipApplicantToPeople < ActiveRecord::Migration
  def change
    add_column :people, :scholarship_applicant, :boolean, :default=>false
  end
end
