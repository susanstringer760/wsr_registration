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

     # update parameters 
     occupancy = params[:occupancy].to_s
     #occupancy = params[:occupancy].to_i
     #balance_due = params[:balance_due]
     balance_due = 0.0
     payment_status = params[:payment_status]
     registration_status = params[:registration_status]
     wait_list_num = params[:wait_list_num].to_i
     total_due = 0.0 
     paid_amount = params[:paid_amount].to_f
     #scholarship_amount = params[:scholarship_amount].to_f
     #scholarship_donation = params[:scholarship_donation].to_f
     scholarship_amount = 0.0
     scholarship_donation = 0.0
     #scholarship_applicant = (params[:scholarship_applicant] == 0 ) ? "false" : "true"
     scholarship_applicant = (params[:scholarship_applicant].to_i == 0 ) ? "false" : "true"

     if ( registration_status.eql?('facilitator')) 
       payment_status = 'paid'
       scholarship_donation = paid_amount
     else 
       #total_due = pricing[occupancy-1]
       total_due = pricing[occupancy].to_f
       balance_due =  total_due - paid_amount - scholarship_amount 
       if ( balance_due <= 0)
         registration_status = 'registered'
	 scholarship_donation = balance_due.abs
	 balance_due = 0.0
         payment_status = 'paid'
       else
         registration_status = 'pending' unless registration_status.eql?('hold');
         payment_status = 'partial';
       end
       if ( wait_list_num > 0 )
         balance_due = 0.0
	 total_due = 0.0
	 registration_status = 'wait_list'
	 scholarship_donation = 0.0
       end
     end

     params[:occupancy] =  occupancy.to_i
     params[:balance_due] = balance_due
     params[:payment_status] = payment_status
     params[:registration_status] = registration_status
     params[:wait_list_num] = wait_list_num
     params[:total_due] = total_due
     params[:paid_amount] = paid_amount
     params[:scholarship_amount] = scholarship_amount
     params[:scholarship_donation] = scholarship_donation
     params[:scholarship_applicant] = scholarship_applicant

     params

   end

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
     if ( person.roommate_id1 > 0 )
       roommate_person1 = Person.find(person.roommate_id1) 
     end
     if ( person.roommate_id2 > 0 )
       roommate_person2 = Person.find(person.roommate_id2) 
     end

     if ( person.occupancy > 1 ) 
       params.push(["Roommate 1",roommate1])
       #arr = ["Roommate 1", roommate1]
       #arr.push(person.roommate_id1) if (person.roommate_id1 > 0)
       #params.push(arr)
       #params.push(["Roommate 1",roommate1])
       #params.push
     end 
     if ( person.occupancy > 2 ) 
       params.push(["Roommate 2",roommate2])
       #arr = ["Roommate 2", roommate2]
       #arr.push(person.roommate_id2) if (person.roommate_id2 > 0)
       #params.push(arr)
       #params.push(["Roommate 2",roommate2])
     #  params.push(["Roommate 2",roommate2, person.roommate_id2])
     end 

     params

   end

   def self.show_confirmation(person, occupancy_by_id, prices)

     # get the confirmation information
     params = Array.new
     name = "#{person.first_name} #{person.last_name}"
     email = person.email
     phone = person.phone
     total_due = prices[person.occupancy.to_s]
     registration_status = person.registration_status
     payment_status = person.payment_status
     payment_type = person.payment_type
     scholarship_amount = person.scholarship_amount
     scholarship_donation = person.scholarship_donation
     paid_amount = person.paid_amount
     balance_due = person.balance_due
     occupancy = occupancy_by_id[person.occupancy.to_s]
     meal_preference = person.meal_preference
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
     #params.push(["Payment status",  payment_status.to_s]);
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
     params.push(["Meal preference",  meal_preference.to_s]);
     #params.push(["Can drive number",  can_drive_num.to_s]) if (!can_drive_num.blank?)
     params.push(["Can drive number",  can_drive_num.to_s]) if (can_drive_num > 0)
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

    # temporary to print out all email addresses for mass mailing
    f = File.new('/Users/snorman/rails_tmp/wsr_registration/reports/email.list', 'w')
    email_arr = Array.new
    blank_arr = Array.new
    people = Person.find(:all)
    count = 0
    people.each do |p|
      if (p.email.blank?)
        name = "  #{p.first_name} #{p.last_name}"
        blank_arr.push(name)
      else
        email_arr.push(p.email)
      end
      count = count+1
    end
    email_str = email_arr.join(',')
    f.puts(email_str)
    f.puts("Email address not available")
    blank_arr.each do |p|
      f.puts(p)
    end
    f.close
    return

    # get a list of people
    sort_by = 'last_name'
    people = self.sort_by(sort_by)
    people = Person.find(:all, :order=>'roommate_id1,roommate_id2')
    f = File.new(csv_fname, 'w')
    #header = "Name,Email,Phone,Occupancy,Payment status,Roommate1,Roommate2"
    header = "Name,Email,Phone,Food,Occupancy,Payment status,Roommate1,Roommate2"
    f.puts(header)

    # print out the rooomate info for each person
    people.each do |p|
      #next if (p.occupancy==3 and p.roommate_id1 > 0 and p.roommate_id2 > 0)
      #next if (p.occupancy==2 and p.roommate_id1 > 0)
      #next if (p.occupancy==1)
      next if (!p.wait_list_num.nil?)
      info = Array.new
      # name
      info.push("#{p.first_name} #{p.last_name}")
      # email
      info.push(p.email)
      # phone
      info.push(p.phone)
      info.push(p.meal_preference)
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
        roommate2 = 'TBD' if p.roommate_id2==0;
      end
      info.push(roommate1)
      info.push(roommate2)


      str = info.join(',')
      f.puts(str)
    end

    f.close

    return


  end

  def self.scholarship_applicants()

    # get a list of scholarship only

    sort_by = 'balance_due'
    # get a list of people
    people = Person.find(:all, :conditions=>{:scholarship_applicant=>1}, :order=>'balance_due')

    arr = Array.new
    arr.push("***** SCHOLARSHIP APPLICANTS *****")
    people.reverse.each do |p|
      arr.push("Name: #{p.first_name} #{p.last_name}")
      arr.push("Status: #{p.registration_status}")
      arr.push("Paid: #{p.paid_amount}")
      if ( p.balance_due < 0 )
        arr.push("Donation: #{p.balance_due.abs}")
      else
        arr.push("Balance due: #{p.balance_due}")
      end
      if ( p.scholarship_amount > 0 )
        arr.push("Scholarship: #{p.scholarship_amount}")
      end
      arr.push("----------------------")
    end
    arr.push("***** NON SCHOLARSHIP APPLICANTS *****")

    arr

  end



  def self.generate_csv(facilitators, occupancy_hash, initial_scholarship, csv_fname)

    notes_fname = csv_fname.gsub('csv','notes.csv');

    f = File.new(csv_fname,'w')

    date_time = DateTime.now.strftime("%F %T")

    # overall stats
    overall_header_arr = self.overall_stats_header()
    overall_header_arr.unshift("Report date")
    overall_header_arr.unshift("Overall stats,,,,,,,,,,,,,,,,,,,,,,,")
    overall_stats_arr = self.overall_registration_stats(facilitators, initial_scholarship)
    #xx = self.overall_registration_stats(facilitators, initial_scholarship)
#return xx
    overall_stats_arr.unshift("#{date_time}")
    overall_stats_arr.unshift("")
    overall_header_arr.each_index do |i|
      f.puts("#{overall_header_arr[i]},#{overall_stats_arr[i]}")
    end
    f.puts("Contact information,,,,Payment information,,,,,,Registration information")

    # individual stats
    person_header_arr = self.person_header()
    person_header_str = person_header_arr.join(',')
    f.puts("#{person_header_str}")

    # get a list of people
    people = Person.all
    people.each do |p|
      occupancy = occupancy_hash[p.occupancy.to_s]
      person_stats_arr = self.person_stats(p, occupancy)
      person_stats_str = person_stats_arr.join(',')
      f.puts("#{person_stats_str}")
    end
    f.close

    # notes
    f = File.new(notes_fname,'w')
    people.each do |p|
      notes = self.get_filtered_notes(p, 'all')
      notes_arr = Array.new
      notes_arr.push("#{p.first_name} #{p.last_name}")
      notes.each do |n|
        notes_arr.push(n.date_time)
        notes_arr.push(n.note_type)
	n.content = n.content.gsub(/\r/," ")
	n.content = n.content.gsub(/\n/," ")
        notes_arr.push(n.content)
      end
      notes_str = notes_arr.join(',')
      f.puts("#{notes_str}")
    end
    f.close

  end

  def self.overall_stats_header()

    # header for overall registration stats
    header_arr = Array.new
    header_arr.push("# Single")
    header_arr.push("# Double")
    header_arr.push("# Triple")
    header_arr.push("# registered")
    header_arr.push("# pending")
    header_arr.push("# hold")
    header_arr.push("# Scholarship requested")
    header_arr.push("Total due")
    header_arr.push("Total paid")
    header_arr.push("Balance due")
    #header_arr.push("Scholarship requested")
    header_arr.push("Scholarships given")
    header_arr.push("Scholarships available")

    return header_arr

  end

  def self.overall_registration_stats(facilitators, initial_scholarship)

    # get the overall registration stats 
    sort_by = 'balance_due'

    # get a list of people
    people = Person.all
    people = self.sort_by(sort_by)

    # amount to deduct for facilitators
    facilitator_deduction = 0
    facilitators.each do |f|
      facilitator_deduction += f.total_due
    end
#xx = Array.new
#xx.push("asdf: #{facilitator_deduction}")

    # get counts for waitlisted people so they're not included in totals
    triple_waitlist = Person.count(:all, :conditions => ["registration_status = ? AND occupancy = ?", "wait_list", 3])
    double_waitlist = Person.count(:all, :conditions => ["registration_status = ? AND occupancy = ?", "wait_list", 2])
    single_waitlist = Person.count(:all, :conditions => ["registration_status = ? AND occupancy = ?", "wait_list", 1])
    # room count totals
    single = get_count('occupancy', '1') - single_waitlist
    double = get_count('occupancy', '2') - double_waitlist
    triple = get_count('occupancy', '3') - triple_waitlist

    # registration stats 
    # don't include wait listed people in total due
    wait_list_total_due = Person.sum(:total_due, :conditions=>{:registration_status=>'wait_list'})
    total_due = self.sum('total_due') - facilitator_deduction - wait_list_total_due

    # scholarship info
    donated_scholarships = self.sum('scholarship_donation')
    initial_scholarship_amount = initial_scholarship
    total_scholarship_applicants = self.get_count('scholarship_applicant', '1')
    total_scholarship_given = self.sum('scholarship_amount')
    total_available_scholarships = initial_scholarship_amount + donated_scholarships - total_scholarship_given

    # balance due
    # don't need to deduct waitlist since their balance due is set to 0
    #total_balance_due = self.sum('balance_due') + total_scholarship_given
    total_balance_due = self.sum('balance_due')

    # deduct donated scholarships from total paid so it isn't include 2 times in report
    total_paid = self.sum('paid_amount') - facilitator_deduction - self.sum('scholarship_donation')
    #total_paid = self.sum('paid_amount') - facilitator_deduction - self.sum('scholarship_donation') + self.sum('scholarship_amount')

    # number on wait list
    total_registered = Person.all.length 
    #total_waitlist_count = 
    registered_pending_count = self.get_count('registration_status', 'pending')
    registered_paid_count = self.get_count('registration_status', 'registered') - facilitators.length
    registered_hold_count = self.get_count('registration_status', 'hold')

    # room counts
    stats_arr = Array.new
    stats_arr.push(single)
    stats_arr.push(double)
    stats_arr.push(triple)

    # registration counts
    #stats_arr.push(total_registered)
    stats_arr.push(registered_paid_count)
    stats_arr.push(registered_pending_count)
    stats_arr.push(registered_hold_count)
    stats_arr.push(total_scholarship_applicants)

    # payment information
    stats_arr.push(total_due)
    stats_arr.push(total_paid)
    stats_arr.push(total_balance_due)
    #stats_arr.push(total_scholarship_applicants)
    stats_arr.push(total_scholarship_given)
    stats_arr.push(total_available_scholarships)

    return stats_arr

  end

  def self.person_header()

 
    # header for registration stats
    header_arr = Array.new
    header_arr.push('First')
    header_arr.push('Last')
    header_arr.push('Email')
    header_arr.push('Phone')
    header_arr.push('Total due')
    header_arr.push('Paid')
    header_arr.push('Scholarship')
    header_arr.push('Scholarship donation')
    header_arr.push('Balance')
    header_arr.push('Payment status')
    header_arr.push('Registration status')
    header_arr.push('Paid date')

    # roommate information
    header_arr.push('Occupancy')
    header_arr.push('Roomie 1')
    header_arr.push('Roomie 2')
    header_arr.push('Meal preference')
    header_arr.push('Scholarship applicant')
    header_arr.push('Can drive')
    header_arr.push('Needs ride')
    #header_arr.push('Registration date')
    #header_arr.push('Due date')
    header_arr.push('Wait list num')
    header_arr.push('Type')
    #header_arr.push('Check num')

    return header_arr
  
  end

  def self.person_stats(person, occupancy)

    # person registration stats
    person_stats_arr = Array.new
    person_stats_arr.push(person.first_name)
    person_stats_arr.push(person.last_name)
    person_stats_arr.push(person.email)
    person_stats_arr.push(person.phone)
    person_stats_arr.push(person.total_due)
    person_stats_arr.push(person.paid_amount)
    person_stats_arr.push(person.scholarship_amount)
    person_stats_arr.push(person.scholarship_donation)
    person_stats_arr.push(person.balance_due)
    person_stats_arr.push(person.payment_status)
    person_stats_arr.push(person.registration_status)
    person_stats_arr.push(person.paid_date)

    # roommate information
    person_stats_arr.push(occupancy)
    roommate1 = self.get_roommate(person.roommate_id1)
    roommate2 = self.get_roommate(person.roommate_id2)
    if ( person.occupancy==1 )
      roommate1 = 'N/A'
      roommate2 = 'N/A'
    end
    if ( person.occupancy==2 )
      roommate1 = 'TBD' if person.roommate_id1==0;
      roommate2 = 'N/A'
    end
    if ( person.occupancy==3 )
      roommate1 = 'TBD' if person.roommate_id1==0;
      roommate2 = 'TBD' if person.roommate_id2==0;
    end
    person_stats_arr.push(roommate1)
    person_stats_arr.push(roommate2)

    person_stats_arr.push(person.meal_preference)
    #scholarship_applicant = (person.scholarship_applicant.to_s.eql?('true')) ?
    #scholarship_applicant = (person.scholarship_applicant==0) ? "no" : "yes"
    person_stats_arr.push(person.scholarship_applicant.to_s)
    #person_stats_arr.push(person.scholarship_applicant)
    person_stats_arr.push(person.can_drive_num)
    #needs_ride = (person.needs_ride==0) ? "no" : "yes"
    person_stats_arr.push(person.needs_ride.to_s)
    #person_stats_arr.push(person.needs_ride)
    #person_stats_arr.push(person.registration_date)
    #person_stats_arr.push(person.due_date)
    person_stats_arr.push(person.wait_list_num)
    person_stats_arr.push(person.payment_type)
    #person_stats_arr.push(person.check_num)

    person_stats_arr
  
  end

  def self.xxxx(facilitators, initial_scholarship, csv_fname)

    # header
    date_time = DateTime.now.strftime("%F %T")
    header_arr = Array.new
    header_arr.push('Report date')
    # status
    stats_arr = Array.new
    stats_arr.push(date_time)

    sort_by = 'balance_due'

    # get a list of people
    people = Person.all
    people = self.sort_by(sort_by)

    # amount to deduct for facilitators
    facilitator_deduction = 0
    facilitators.each do |f|
      facilitator_deduction += f.total_due
    end

    # get counts for waitlisted people
    # so they're not included in totals
    triple_waitlist = Person.count(:all, :conditions => ["registration_status = ? AND occupancy = ?", "wait_list", 3])
    double_waitlist = Person.count(:all, :conditions => ["registration_status = ? AND occupancy = ?", "wait_list", 2])
    single_waitlist = Person.count(:all, :conditions => ["registration_status = ? AND occupancy = ?", "wait_list", 1])
    # room count totals
    single = get_count('occupancy', '1') - single_waitlist
    double = get_count('occupancy', '2') - double_waitlist
    triple = get_count('occupancy', '3') - triple_waitlist


    # registration stats 
    # don't include wait listed people in total due
    wait_list_total_due = Person.sum(:total_due, :conditions=>{:registration_status=>'wait_list'})
    total_due = self.sum('total_due') - facilitator_deduction - wait_list_total_due

    # scholarship info
    donated_scholarships = self.sum('scholarship_donation')
    initial_scholarship_amount = initial_scholarship
    total_scholarship_applicants = self.get_count('scholarship_applicant', '1')
    total_scholarship_given = self.sum('scholarship_amount')
    total_available_scholarships = initial_scholarship_amount + donated_scholarships - total_scholarship_given

    # balance due
    # don't need to deduct waitlist since their balance due is set to 0
    #total_balance_due = self.sum('balance_due') + total_scholarship_given
    total_balance_due = self.sum('balance_due')


    # deduct donated scholarships from total paid so it isn't include 2 times in report
    total_paid = self.sum('paid_amount') - facilitator_deduction - self.sum('scholarship_donation')
    #total_paid = self.sum('paid_amount') - facilitator_deduction - self.sum('scholarship_donation') + self.sum('scholarship_amount')

    # number on wait list
    total_registered = Person.all.length 
    total_waitlist_count = 
    registered_pending_count = self.get_count('registration_status', 'pending')
    registered_paid_count = self.get_count('registration_status', 'registered') - facilitators.length
    registered_hold_count = self.get_count('registration_status', 'hold')

    # room counts
    header_arr.push('# Single')
    stats_arr.push(single)
    header_arr.push('# Double')
    stats_arr.push(double)
    header_arr.push('# Triple')
    stats_arr.push(triple)

    # registration counts
    header_arr.push('# registered')
    stats_arr.push(total_registered)
    header_arr.push('# pending')
    stats_arr.push(registered_pending_count)
    header_arr.push('# hold')
    stats_arr.push(registered_hold_count)

    # payment information
    header_arr.push('Total due')
    stats_arr.push(total_due)

    header_arr.push('Total paid')
    stats_arr.push(total_paid)

    header_arr.push('Balance due')
    stats_arr.push(total_balance_due)

    header_arr.push('Scholarship requested')
    stats_arr.push(total_scholarship_applicants)

    header_arr.push('Scholarships given')
    stats_arr.push(total_scholarship_given)

    header_arr.push('Scholarships available')
    stats_arr.push(total_available_scholarships)


    final_arr = Array.new
    header_arr.each_index do |i|
      f.puts("#{header_arr[i]};#{stats_arr[i]}")
      #f.puts("#{stats_arr[i]}")
      #header_str = header_arr.join(';')
      #stats_str = stats_arr.join(';')
      #f.puts("#{header_str}")
      #f.puts("#{stats_str}")
      #f.puts("#{header_arr[i]}
      #f.puts("#{stats_arr[i]};;;;;;;;;;;;;;;;;;;;;;;")
    end
    f.close
    #return
    #final_arr.unshift('REGISTRATION STATS:');
    #final_str = final_arr.join(';')


      # header
      date_time = DateTime.now.strftime("%F %T")
      header_arr = Array.new
      header_arr.push('Report date')
      # person info 
      person_arr = Array.new
      person_arr.push("#{date_time}")


      p = Person.find(48)
      person_arr.push(p.last_name)
      person_arr.push(p.first_name)
      person_arr.push(p.email)
      person_arr.push(p.phone)
      person_arr.push(p.payment_type)
      person_arr.push(p.payment_status)
      person_arr.push(p.registration_status)
      person_arr.push(p.paid_amount)
      person_arr.push(p.scholarship_amount)
      person_arr.push(p.scholarship_donation)
      person_arr.push(p.balance_due)
      person_arr.push(p.occupancy)
      person_arr.push(p.check_num)
      person_arr.push(p.can_drive_num)
      person_arr.push(p.wait_list_num)
      person_arr.push(p.roommate_id1)
      person_arr.push(p.roommate_id2)
      person_arr.push(p.needs_ride)
      person_arr.push(p.paid_date)
      person_arr.push(p.registration_date)
      person_arr.push(p.due_date)
      person_arr.push(p.total_due)
      person_arr.push(p.meal_preference)
      person_arr.push(p.scholarship_applicant)
      return "#{person_arr.length} and #{header_arr.length} and #{stats_arr.length}"

      #header_arr.push(';;;;;;;;;;;;;;;;;;;;;;;;');
      header_arr.push('last name')
      header_arr.push('first name')
      header_arr.push('email')
      header_arr.push('phone')
      header_arr.push('payment type')
      header_arr.push('payment status')
      header_arr.push('registration status')
      header_arr.push('paid amount')
      header_arr.push('scholarship amount')
      header_arr.push('scholarship donation')
      header_arr.push('balance due')
      header_arr.push('occupancy')
      header_arr.push('check num')
      header_arr.push('can drive num')
      header_arr.push('wait list num')
      header_arr.push('roommate id1')
      header_arr.push('roommate id2')
      header_arr.push('needs ride')
      header_arr.push('paid date')
      header_arr.push('registration date')
      header_arr.push('due date')
      header_arr.push('total due')
      header_arr.push('meal preference')
      header_arr.push('scholarship applicant')

      header_str = header_arr.join(',')
      person_str = person_arr.join(',')
      f.puts(header_str)
      f.puts(person_str)
      f.close
      return ""



##      p = Person.find(48)
##      arr = Array.new
##      header_arr = Array.new
##      header_arr.push(';;;;;;;;;;;;;;;;;;;;')
##      header_arr.push('First')
##      header_arr.push('Last')
##      header_arr.push('Email')
##      header_arr.push('phone')
##      header_arr.push('payment status')
##      header_arr.push('registration status')
##      header_arr.push('paid amount')
##      header_arr.push('scholarship amount')
##      header_arr.push('scholarship donation')
##      header_arr.push('balance due')
##      header_arr.push('occupancy')
##      header_arr.push('check num')
##      header_arr.push('wait list num')
##      header_arr.push('needs ride')
##      header_arr.push('paid date')
##      header_arr.push('registration date')
##      header_arr.push('due date')
##      header_arr.push('total due')
##      header_arr.push('meal preference')
##      header_arr.push('scholarship applicant')

##      person_arr.push(p.first_name)
##      person_arr.push(p.last_name)
##      person_arr.push(p.email)
##      person_arr.push(p.phone)
##      person_arr.push(p.payment_status)
##      person_arr.push(p.registration_status)
##      person_arr.push(p.paid_amount)
##      person_arr.push(p.scholarship_amount)
##      person_arr.push(p.scholarship_donation)
##      person_arr.push(p.balance_due)
##      person_arr.push(p.occupancy)
##      person_arr.push(p.check_num)
##      person_arr.push(p.wait_list_num)
##      person_arr.push(p.needs_ride)
##      person_arr.push(p.paid_date)
##      person_arr.push(p.registration_date)
##      person_arr.push(p.due_date)
##      person_arr.push(p.total_due)
##      person_arr.push(p.meal_preference)
##      person_arr.push(p.scholarship_applicant)
      #next if ((split_report.eql?('true')) and (p.scholarship_applicant) )

    people.reverse.each do |p|
      arr.push(p.first_name)
      arr.push(p.last_name)
      arr.push(p.email)
      arr.push(p.phone)
      arr.push(p.payment_status)
      arr.push(p.paid_amount)
      arr.push(p.scholarship_amount)
      arr.push(p.scholarship_donation)
      arr.push(p.balance_due)
      arr.push(p.occupancy)
      arr.push(p.check_num)
      arr.push(p.wait_list_num)
      arr.push(p.needs_ride)
      arr.push(p.paid_date)
      arr.push(p.registration_date)
      arr.push(p.due_date)
      arr.push(p.total_due)
      arr.push(p.meal_preference)
      arr.push(p.scholarship_applicant)
      return arr
      #next if ((split_report.eql?('true')) and (p.scholarship_applicant) )
      #next if (p.last_name.eql?(facilitators[0].last_name))
      #next if (p.last_name.eql?(facilitators[1].last_name))
      #arr.push("--------------------")
      jtats_arr = Array.new
      arr.push("Name: #{p.first_name} #{p.last_name}\n")
      stats_arr.push("Status: #{p.registration_status}")
      stats_arr.push("Paid: #{p.paid_amount}")
      if ( p.balance_due < 0 )
        stats_arr.push("Donation: #{p.balance_due.abs}")
      else
        stats_arr.push("Balance due: #{p.balance_due}")
      end
      if ( p.scholarship_amount > 0 )
        stats_arr.push("Scholarship: #{p.scholarship_amount}")
      end
      stats_arr.push("Meal preference: #{p.meal_preference}")
      if ( !p.wait_list_num.nil? )
        stats_arr.push("Wait list #: #{p.wait_list_num}")
      end
      stats_str = stats_arr.join('; ')
      arr.push(stats_str);
    end

    arr

  end


  def self.report(facilitators, initial_scholarship, split_report)

    sort_by = 'balance_due'

    # get a list of people
    people = self.sort_by(sort_by)

    # amount to deduct for facilitators
    facilitator_deduction = 0
    facilitators.each do |f|
      facilitator_deduction += f.total_due
    end

    # get counts for waitlisted people
    # so they're not included in totals
    triple_waitlist = Person.count(:all, :conditions => ["registration_status = ? AND occupancy = ?", "wait_list", 2])
    double_waitlist = Person.count(:all, :conditions => ["registration_status = ? AND occupancy = ?", "wait_list", 1])
    single_waitlist = Person.count(:all, :conditions => ["registration_status = ? AND occupancy = ?", "wait_list", 0])
    # room count totals
    single = get_count('occupancy', '1') - single_waitlist
    double = get_count('occupancy', '2') - double_waitlist
    triple = get_count('occupancy', '3') - triple_waitlist

    # registration stats 
    # don't include wait listed people in total due
    wait_list_total_due = Person.sum(:total_due, :conditions=>{:registration_status=>'wait_list'})
    total_due = self.sum('total_due') - facilitator_deduction - wait_list_total_due

    # total due
    #total_due = self.sum('total_due') - facilitator_deduction

    # scholarship info
    donated_scholarships = self.sum('scholarship_donation')
    initial_scholarship_amount = initial_scholarship
    total_scholarship_applicants = self.get_count('scholarship_applicant', '1')
    total_scholarship_given = self.sum('scholarship_amount')
    total_available_scholarships = initial_scholarship_amount + donated_scholarships - total_scholarship_given

    # balance due
    # don't need to deduct waitlist since their balance due is set to 0
    #total_balance_due = self.sum('balance_due') + total_scholarship_given
    total_balance_due = self.sum('balance_due')

    # deduct donated scholarships from total paid so it isn't include 2 times in report
    total_paid = self.sum('paid_amount') - facilitator_deduction - self.sum('scholarship_donation')
    #total_paid = self.sum('paid_amount') - facilitator_deduction - self.sum('scholarship_donation') + self.sum('scholarship_amount')

    # number on wait list
    total_registered = Person.all.length - 
    registered_pending_count = self.get_count('registration_status', 'pending')
    registered_paid_count = self.get_count('registration_status', 'registered') - facilitators.length
    registered_hold_count = self.get_count('registration_status', 'hold')

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

    # scholarship applicants
    if ( split_report.eql?('true'))
      arr.concat(scholarship_applicants = self.scholarship_applicants())
    end

    people.reverse.each do |p|
      next if ((split_report.eql?('true')) and (p.scholarship_applicant) )
      facilitators.each do |f|
        next if (p.last_name.eql?(f.last_name));
      end
      #next if (p.last_name.eql?(facilitators[0].last_name))
      #next if (p.last_name.eql?(facilitators[1].last_name))
      arr.push("--------------------")
      stats_arr = Array.new
      arr.push("Name: #{p.first_name} #{p.last_name}\n")
      stats_arr.push("Status: #{p.registration_status}")
      stats_arr.push("Paid: #{p.paid_amount}")
      if ( p.balance_due < 0 )
        stats_arr.push("Donation: #{p.balance_due.abs}")
      else
        stats_arr.push("Balance due: #{p.balance_due}")
      end
      if ( p.scholarship_amount > 0 )
        stats_arr.push("Scholarship: #{p.scholarship_amount}")
      end
      stats_arr.push("Meal preference: #{p.meal_preference}")
      if ( !p.wait_list_num.nil? )
        stats_arr.push("Wait list #: #{p.wait_list_num}")
      end
      stats_str = stats_arr.join('; ')
      arr.push(stats_str);
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
    #note_hash[key] = Note.find(:all,:conditions => ["person_id= ? AND note_type= ?", person.id, "email_log"])
    #note_hash[person.id] = Note.find(:all,:conditions => ["person_id= ? AND note_type= ?", person.id, "email_log"])
    #note_hash[person.id] = Note.find(:all,:conditions => ["person_id= ? AND note_type= ? and content=?", person.id, "email_log", "confirmation sent"])
    note_hash[person.id] = Note.find(:all,:conditions => ["person_id= ? AND note_type= ?", person.id, "email_log", ])

    return note_hash


  end

  def self.generate_email_log(person_id, confirmation_type)

    # create a note to log the confirmation email
    email_log_note = Note.new(:date_time=>Time.now, :content=>'confirmation sent', :person_id=>person_id, :note_type=>'email_log') if (confirmation_type.eql?('confirm'))

    # reminder
    email_log_note = Note.new(:date_time=>Time.now, :content=>'reminder sent', :person_id=>person_id, :note_type=>'email_log') if (confirmation_type.eql?('reminder'))

    # final 
    email_log_note = Note.new(:date_time=>Time.now, :content=>'final confirmation sent', :person_id=>person_id, :note_type=>'email_log') if (confirmation_type.eql?('final'))

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
