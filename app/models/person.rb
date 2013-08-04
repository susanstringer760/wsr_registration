class Person < ActiveRecord::Base
  #attr_accessible :address, :city, :email, :name, :phone, :zip
  attr_accessible :last_name,
   :first_name,
   :address,
   :city,
   :zip,
   :email,
   :phone,
   :payment_type,
   :payment_status,
   :registration_status,
   :paid_amount,
   :scholarship_amount,
   :scholarship_donation,
   :balance_due,
   :occupancy,
   :check_num,
   :can_drive_num,
   :wait_list_num,
   :roommate_id1,
   :roommate_id2,
   :needs_ride,
   :paid_date,
   :registration_date,
   :due_date,
   :total_due,
   :scholarship_applicant,
   :meal_preference,
   :notes

   has_many :notes, :dependent=>:destroy

   validates :last_name, :presence => true
   validates :first_name, :presence => true
   validates :last_name, :uniqueness => {:scope => :first_name, :message => 'cannot have two entries with same first and last name'}
   validate :roommate_test, :validate_payment

   #*** start validations ***
   # set registration to current date
   def after_initialize
      self.registration_date ||= Date.today if new_record?
   end

   def validate_payment
     if ( payment_type.eql?('check') && check_num.blank? )
       errors.add(:payment_type, "check number must be entered") 
     end
   end

   def roommate_test
     if (roommate_id1.eql?(roommate_id2))
       errors.add(:name, "cannot have duplicate roommates") unless (roommate_id1==0 && roommate_id2==0)
     end
     roommate_count = 0 
     roommate_count += 1 if (roommate_id1 > 0) 
     roommate_count += 1 if (roommate_id2 > 0) 
     if ( occupancy <= roommate_count )
       errors.add(:name, "too many rommates for occupancy")
     end
   end

   #*** end validations ***

   def self.sort_by(value_to_sort)

     # return a list of sorted transactions
     sort_by_sym = value_to_sort.to_sym
     return Person.all(:order=>sort_by_sym)

     #return Person.all(:conditions=>{:bank_account_id=>bank_account.id}, :order=>sort_by_sym)

   end

   def self.set_values(params, pricing)

     # calculate all the price dependent values

     # balance due
     occupancy = params[:occupancy].to_i
     total_due = pricing[occupancy]
     paid_amount = params[:paid_amount].to_f
     scholarship_amount = params[:scholarship_amount].to_f
     balance_due =  total_due - paid_amount - scholarship_amount 

     # payment status
     payment_status = 'paid' if (balance_due <= 0)
     payment_status = 'pending' if (balance_due > 0 )

     registration_status = 'registered' if (balance_due <= 0)
     registration_status = 'pending' if (balance_due > 0)
     # registration status
     if ( params[:registration_status].eql?('hold'))
       registration_status = params[:registration_status]
     else
       registration_status = 'registered' if (balance_due <= 0)
       registration_status = 'pending' if (balance_due > 0)
     end

     # set the new values
     if ( balance_due < 0 )
       params[:scholarship_donation] = balance_due.abs 
       balance_due = 0
     end
     params[:balance_due] = balance_due.to_f
     params[:payment_status] = payment_status
     params[:registration_status] = registration_status
     params[:total_due] = total_due 

     params

   end

   #def self.balance_due(params, pricing)
   def self.balance_due(amount_paid, total_price)

     # calculate the balance due
     #occupancy = params[:occupancy].to_i

     #price = pricing[occupancy]

     #amount_paid = params[:paid_amount].to_f

     balance_due = total_price - amount_paid.to_f

     return balance_due

   end

   def self.scholarship_donation(balance_due, total_price)

     diff = total_price + balance_due
     return "#{total_price} and #{balance_due} and #{diff}"

   end

   def self.payment_status(balance_due)

   #  price = pricing[person.occupancy]
   #  paid_amount = person.paid_amount
   #  payment_status = person.payment_status


     payment_status = 'paid' if (balance_due <= 0)
     #payment_status = 'partial' if (balance_due > 0 )
     payment_status = 'pending' if (balance_due > 0 )
     return "#{balance_due} and #{payment_status}"

     payment_status

   end

   def self.roommate_list(id)

     # array of available roommates
     # if id is 0, then return a list
     # of all people
     list = Array.new
     people = Person.find(:all, :order => "last_name")
     people.each do |p|
       name = "#{p.first_name} #{p.last_name}"
       list.push([name ,p.id]) if ((id != p.id) || (id != 0))
     end
     #list.unshift(['NONE', 0])
     list.unshift(['TBD', 0])

     return list

   end

   def self.roommate_hash

     # get an array where each element
     # is an array with name,id
     roommate_hash = Hash.new
     roommate_list = roommate_list(0)
     roommate_list.each do |r|
       key = r[1].to_s
       value = r[0]
       roommate_hash[key] = value
     end

     roommate_hash

   end

   def self.show_person(person, occupancy_by_id, prices)

     params = Array.new
     name = "#{person.first_name} #{person.last_name}"
     params.push(['Name', name])

     person.attributes.each {|key, value| 
       next if (key.eql?('id'))
       next if (key.eql?('first_name'))
       next if (key.eql?('last_name'))
       next if (key.eql?('roommate_id1')) 
       next if (key.eql?('roommate_id2')) 
       next if (key.eql?('updated_at'))
       next if (key.eql?('created_at'))
       next if (value.blank?) 

       if ( key.eql?('occupancy')) 
         value = occupancy_by_id[value.to_s] 
       end 
       param = [key.capitalize, value]
       params.push(param)
     } 

     # roommate info
     roommate1 = Person.get_roommate(person.roommate_id1)
     roommate2 = Person.get_roommate(person.roommate_id2)
     if ( person.occupancy > 1 ) 
       params.push(["Roommate 1",roommate1])
     end 
     if ( person.occupancy > 2 ) 
       params.push(["Roommate 2",roommate2])
     end 

     params

   end

   def self.show_confirmation(person, occupancy_by_id, prices)

     # get the confirmation information
     params = Array.new
     name = "#{person.first_name} #{person.last_name}"
     email = person.email
     phone = person.phone
     total_due = prices[person.occupancy]
     registration_status = person.registration_status
     payment_status = person.payment_status
     payment_type = person.payment_type
     scholarship_amount = person.scholarship_amount
     scholarship_donation = person.scholarship_donation
     paid_amount = person.paid_amount
     balance_due = person.balance_due
     occupancy = occupancy_by_id[person.occupancy.to_s]
     check_number = person.check_num
     can_drive_num = person.can_drive_num
     needs_ride = person.needs_ride
     wait_list_num = person.wait_list_num
     roommate_id1 = person.roommate_id1 
     roommate_id2 = person.roommate_id2 
   
     if (roommate_id1 > 0 )
       first_name = Person.find(roommate_id1).first_name
       last_name = Person.find(roommate_id1).last_name
       roommate1 = "#{first_name} #{last_name}"
     else 
       roommate1 = 'TBD'
     end
     if (roommate_id2 > 0 )
       first_name = Person.find(roommate_id2).first_name
       last_name = Person.find(roommate_id2).last_name
       roommate2 = "#{first_name} #{last_name}"
     else 
       roommate2 = 'TBD'
     end

     # stuff the necessary parameters into an array 
     params.push(["Name", name.to_s]);
     params.push(["Phone", phone.to_s]);
     params.push(["Registration status",  registration_status.to_s]);
     params.push(["Payment status",  payment_status.to_s]);
     params.push(["Total due",  to_currency(total_due).to_s]);
     params.push(["Paid",  to_currency(paid_amount).to_s]);
     params.push(["Balance due",  to_currency(balance_due).to_s]);
     #params.push(["Payment type",  payment_type.to_s]) if (balance_due == 0)
     #if ( (!check_number.blank?) && (payment_type.eql?('check')) )
     #  params.push(["Check number",  check_number.to_s])
     #end
     params.push(["Scholarship amount",  to_currency(scholarship_amount).to_s]) if (scholarship_amount > 0)
     params.push(["Scholarship donation ",  to_currency(scholarship_donation).to_s]) if (scholarship_donation > 0)
     params.push(["Occupancy",  occupancy.to_s]);
     params.push(["Roommate 1",  roommate1.to_s]) if (person.occupancy > 1);
     params.push(["Roommate 2",  roommate2.to_s]) if (person.occupancy > 2);
     params.push(["Can drive number",  can_drive_num.to_s]) if (!can_drive_num.blank?)
     params.push(["Needs ride",  needs_ride.to_s]) if (!needs_ride.blank?)

     params

   end

   def self.sshow_confirmation(person, occupancy_by_id, prices)

     # get the confirmation information
     params = Array.new
     name = "#{person.first_name} #{person.last_name}"
     email = person.email
     phone = person.phone
     total_due = prices[person.occupancy]
     registration_status = person.registration_status
     payment_status = person.payment_status
     payment_type = person.payment_type
     scholarship_amount = person.scholarship_amount
     scholarship_donation = person.scholarship_donation
     paid_amount = person.paid_amount
     balance_due = person.balance_due
     occupancy = occupancy_by_id[person.occupancy.to_s]
     check_number = person.check_num
     can_drive_num = person.can_drive_num
     needs_ride = person.needs_ride
     wait_list_num = person.wait_list_num
     roommate_id1 = person.roommate_id1 
     roommate_id2 = person.roommate_id2 
   
     if (roommate_id1 > 0 )
       first_name = Person.find(roommate_id1).first_name
       last_name = Person.find(roommate_id1).last_name
       roommate1 = "#{first_name} #{last_name}"
     else 
       roommate1 = 'TBD'
     end
     if (roommate_id2 > 0 )
       first_name = Person.find(roommate_id2).first_name
       last_name = Person.find(roommate_id2).last_name
       roommate2 = "#{first_name} #{last_name}"
     else 
       roommate2 = 'TBD'
     end

     params.push("Name: #{name}");
     params.push("Phone: #{phone}");
     params.push("Registration status: #{registration_status}");
     params.push("Payment status: #{payment_status}");
     params.push("Total due: #{to_currency(total_due)}");
     params.push("Paid: #{to_currency(paid_amount)}");
     params.push("Balance due: #{to_currency(balance_due)}");
     params.push("Payment type: #{payment_type}") if (balance_due == 0)
     if ( (!check_number.blank?) && (payment_type.eql?('check')) )
       params.push("Check number: #{check_number}")
     end
     params.push("Scholarship amount: #{to_currency(scholarship_amount)}") if (scholarship_amount > 0)
     params.push("Scholarship donation : #{to_currency(scholarship_donation)}") if (scholarship_donation > 0)
     params.push("Occupancy: #{occupancy}");
     params.push("Roommate 1: #{roommate1}") if (person.occupancy > 1);
     params.push("Roommate 2: #{roommate2}") if (person.occupancy > 2);
     params.push("Can drive number: #{can_drive_num}") if (!can_drive_num.blank?)
     params.push("Needs ride: #{needs_ride}") if (!needs_ride.blank?)

     params

   end

   def self.to_currency(num)

     "$".concat(num.to_s)

  end

  def self.get_count(column_name, condition_value)

    column_name_to_sym = column_name.to_sym
    column_condition = "#{column_name} = '#{condition_value}'"

    return Person.count(column_name_to_sym, :conditions=>"#{column_condition}")

  end

  def self.get_total_due(price_hash)

    # calculate total due
    count_hash = Hash.new
    total_due = 0
    price_hash.each do |p|
      key = p[0]
      # amount by occupancy
      count_by_occupancy = get_count('occupancy', key)
      value_by_occupancy = count_by_occupancy * price_hash[key]
      total_due = total_due + value_by_occupancy
    end

    return total_due

  end

  def self.get_column_total(column_to_total, column_condition, condition_value)

    # get totals for report
    column_to_total_sym = column_to_total.to_sym
    column_condition_sym = column_condition.to_sym
    column_condition = "#{column_condition} = '#{condition_value}'"
    return Person.sum(column_to_total_sym, :conditions=>"#{column_condition}")

  end

  def self.create_roommate_report(csv_fname, occupancy_hash)

    # get a list of people
    sort_by = 'last_name'
    people = self.sort_by(sort_by)
    f = File.new(csv_fname, 'w')
    header = "Name,Email,Phone,Occupancy,Payment status,Roommate1,Roommate2"
    f.puts(header)

    # print out the rooomate info for each person
    people.each do |p|
      info = Array.new
      # name
      info.push("#{p.first_name} #{p.last_name}")
      # email
      info.push(p.email)
      # phone
      info.push(p.phone)
      occupancy = occupancy_hash[p.occupancy.to_s]
      info.push(occupancy)
      info.push(p.payment_status)
      roommate1 = self.get_roommate(p.roommate_id1)
      roommate2 = self.get_roommate(p.roommate_id2)
      if ( occupancy.downcase.eql?('single'))
        roommate1 = 'N/A'
        roommate2 = 'N/A'
      end
      if (occupancy.downcase.eql?('double'))
        roommate1 = 'TBD' if p.roommate_id1==0;
        roommate2 = 'N/A'
      end
      if (occupancy.downcase.eql?('triple'))
        roommate1 = 'TBD' if p.roommate_id1==0;
        roommate1 = 'TBD' if p.roommate_id2==0;
      end
      info.push(roommate1)
      info.push(roommate2)

      str = info.join(',')
      f.puts(str)
    end

    f.close

    return


  end

  def self.report(facilitators, initial_scholarship)

    sort_by = 'last_name'
    # get a list of people
    people = self.sort_by(sort_by)

    # amount to deduct for facilitators
    facilitator_deduction = 0
    facilitators.each do |f|
      facilitator_deduction += f.total_due
    end

    # registration stats
    total_due = self.sum('total_due') - facilitator_deduction
    total_balance_due = self.sum('balance_due')
    donated_scholarships = self.sum('scholarship_donation')
    initial_scholarship_amount = initial_scholarship
    total_scholarship_applicants = self.get_count('scholarship_applicant', '1')
    total_scholarship_given = self.sum('scholarship_amount')
    total_available_scholarships = initial_scholarship_amount + donated_scholarships - total_scholarship_given
    # deduct donated scholarships from total paid so it isn't include 2 times in report
    total_paid = to_currency(self.sum('paid_amount') - facilitator_deduction - self.sum('scholarship_donation'))
    total_registered = Person.all.length
    registered_pending_count = self.get_count('registration_status', 'pending')
    registered_paid_count = self.get_count('registration_status', 'registered')
    registered_hold_count = self.get_count('registration_status', 'hold')

    #available_scholarship = to_currency(initial_scholarship + self.sum('scholarship_donation'))
    #total_paid = to_currency(self.sum('paid_amount') - facilitator_deduction - self.sum('scholarship_donation') - initial_scholarship)
    #total_paid = to_currency(self.sum('paid_amount') - facilitator_deduction)
    # calculate 
    single = get_count('occupancy', '1')
    double = get_count('occupancy', '2')
    triple = get_count('occupancy', '3')
    #single = Person.find(:all, :conditions=>{:occupancy=>1})
    # num_single_rooms = single.length
    #double = Person.find(:all, :conditions=>{:occupancy=>2})
    #num_double_rooms = (double.length.to_f/2.0).ceil
    #triple = Person.find(:all, :conditions=>{:occupancy=>3})
    #num_triple_rooms = (triple.length.to_f/3.0).ceil

    arr = Array.new
    arr.push("Total due: #{to_currency(total_due)}")
    arr.push("Total paid: #{to_currency(total_paid)}")
    arr.push("Total balance due: #{to_currency(total_balance_due)}")
    arr.push("Initial scholarship amount: #{to_currency(initial_scholarship_amount)}")
    arr.push("Donated scholarships: #{to_currency(donated_scholarships)}")
    arr.push("Total available scholarships: #{to_currency(total_available_scholarships)}")
    arr.push("Total scholarship given: #{to_currency(total_scholarship_given)}")
    arr.push("Total scholarship applicants: #{total_scholarship_applicants}")
    arr.push("Total registered: #{total_registered}")
    arr.push("Total registered(pending): #{registered_pending_count}")
    arr.push("Total registered(paid): #{registered_paid_count}")
    arr.push("Total registered(hold): #{registered_hold_count}")
    arr.push("Total single occupancy: #{single}")
    arr.push("Total double occupancy: #{double}")
    arr.push("Total triple occupancy: #{triple}")
    arr.push("******************************")
    people.each do |p|
    facilitators
      next if (p.last_name.eql?(facilitators[0].last_name))
      next if (p.last_name.eql?(facilitators[1].last_name))
      #next if (p.last_name.eql?('Vielbig'))
      #next if (p.last_name.eql?('Bruni'))
      arr.push("#{p.first_name} #{p.last_name}")
      arr.push("Registration status: #{p.registration_status}")
      arr.push("Paid amount: #{p.paid_amount}")
      if ( p.balance_due < 0 )
        arr.push("Donation: #{p.balance_due.abs}")
      else
        arr.push("Balance due: #{p.balance_due}")
      end
      arr.push("--------------------")
    end

    arr



  end


  def self.xxget_notes(person,column,value)

    # return a string containing the notes

    # first get an array of filtered notes
    filtered_notes = get_filtered_notes(person, filter_by)
    arr = Array.new
    filtered_notes.each do |n|
      # stuff into an array
      arr.push(n.content)
      n.content.gsub!(/\r/, '')
    end
    return arr

    # now remove the return characters
    arr.each do |c|
    end

  end

  def self.filter_by(person,column_name, value, order_by)

    # this query returns an active record relation
    # of filtered values for the given column name
    column_name_sym = column_name.to_sym

    # convert query value to symbols
    person_id_sym = person_id.to_s.to_sym

    filter_relation = Person.where(["person_id = ?", person_id_sym]).select(column_name_sym).uniq

    # convert to an array
    tmp_arr = filter_relation.map(&column_name_sym)
    #tmp_arr.unshift('Select one')
    filter_arr = Array.new
    j = 0
    tmp_arr.each_index { |i|
      filter_arr.push([tmp_arr[i], i])
    }
    return filter_arr

  end 
  def self.get_filtered_notes(person, filter_by)

    filtered_notes = Array.new
    person.notes.each do |n|
      filtered_notes.push(n) if (filter_by.eql?(n.note_type) || (filter_by.eql?('all')) )
    end
  
    filtered_notes

  end

  def self.get_roommate(roommate_id)

    # return the name of roommate with the given id
    if (roommate_id.nil? || roommate_id <= 0 )
      return 'TBD'
    else
      last_name = Person.find(roommate_id).last_name
      first_name = Person.find(roommate_id).first_name
      return "#{first_name} #{last_name}"
    end

  end

  def self.get_notes(person)

    # get the notes for the person
    note_type_list = person.notes.select("DISTINCT(notes.note_type)").order("notes.date_time")
    note_value_arr = Array.new
    note_type_hash = Hash.new
    note_type_list.each do |n|
      note_type_hash[n.note_type] = []
    end   
    hash = Hash.new
    note_type_hash.keys.sort.each do |key|
      hash[key] = Note.find(:all,:conditions => ["person_id= ? AND note_type= ?", person.id, key])
    end

    return hash
    
  end

  def self.get_email_log(person)

    # return a hash where the key is the
    # person name and value is array of
    # email log notes
    note_hash = Hash.new
    #key = "#{person.first_name} #{person.last_name}"
    key = "#{person.id};#{person.first_name} #{person.last_name}"
    note_hash[key] = Note.find(:all,:conditions => ["person_id= ? AND note_type= ?", person.id, "email_log"])
    #note_hash[person.id] = Note.find(:all,:conditions => ["person_id= ? AND note_type= ?", person.id, "email_log"])

    return note_hash


  end

  def self.generate_email_log(person_id)

    # create a note to log the confirmation email
    email_log_note = Note.new(:date_time=>Time.now, :content=>'confirmation sent', :person_id=>person_id, :note_type=>'email_log')

    # add the note to the person
    return email_log_note

  end



#  def self.get_roommate(id)
#
#    #person_id = person.id
#    (id == 0) ?
#      roommate = 'TBD' :
#      roommate = Person.where(["id = ?", person_id]).select("roommate_id1,roommate_id2").first
#
#    roommate
#
#  end
end
