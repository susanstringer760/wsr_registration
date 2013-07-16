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
       list.push([name ,p.id]) if ((id != p.id) || (id == 0))
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

   def self.get_confirmation(person, occupancy_by_id, prices)

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

  def self.get_notes(person,column,value)

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
      filtered_notes.push(n) if (filter_by.eql?(n.note_type))
    end
  
    filtered_notes

  end

  def self.get_roommate(roommate_id)

    # return the name of roommate with the given id
    if (roommate_id.nil? || roommate_id <= 0 )
      return 'NONE'
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

  def self.get_roommate(person)

    person_id = person.id
    Person.where(["id = ?", person_id]).select("roommate_id1,roommate_id2").first

  end
end
