class Note < ActiveRecord::Base
  attr_accessible :content, :date_time, :note_type, :person_id

  belongs_to :person
  validates :content, presence: true

  def self.get_people()

     # array of available roommates
     list = Array.new
     people = Person.find(:all, :order => "last_name")
     people.each do |p|
       name = "#{p.first_name} #{p.last_name}"
       list.push([name ,p.id]) 
     end
     list.unshift(['NONE', 0])

     return list

  end

end
