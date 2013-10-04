class PeopleController < ApplicationController

  # GET /people
  # GET /people.json
  def index

  params[:sort_by] ?
    sort_by = params[:sort_by] :
    sort_by = 'last_name'

    # list of people
    # @people = Person.sort_by(sort_by) 
    # set balance due as reverse order
    # so we can tell what is still owed
    if ( sort_by.eql?('balance_due'))
      @people = Person.sort_by(sort_by).reverse() 
    else 
      @people = Person.sort_by(sort_by) 
    end 

    @people_options = @people.collect {|p|["#{p.first_name} #{p.last_name}",p.id]}

    # hash of roommates where key is person id
    # and value is person name
    @roommate_hash = Person.roommate_hash()

    # report to display on index 
    arr = Person.report(@facilitators, @initial_scholarship,false)
    balance_arr = Array.new
    scholarship_arr = Array.new
    registered_arr = Array.new
    occupancy_arr = Array.new

    arr.each do |r|
      break if (r.match(/\*/))
      balance_arr.push(r) if (r.match('due'))
      balance_arr.push(r) if (r.match('Total paid'))
      scholarship_arr.push(r) if (r.match('scholarship'))
      registered_arr.push(r) if (r.match('registered'))
      occupancy_arr.push(r) if (r.match('occupancy'))
    end

    @totals_hash = Hash.new
    @totals_hash['balance'] = balance_arr
#render :text=>"asdf: #{balance_arr}"
#return
    @totals_hash['scholarship'] = scholarship_arr
    @totals_hash['registered'] = registered_arr
    @totals_hash['occupancy'] = occupancy_arr

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @people }
    end

  end

  # GET /people/1
  # GET /people/1.json
  def show

    @person = Person.find(params[:id])
   #render :text=>"in show: #{@person.first_name}: #{@person.registration_status}"
   #return
    #@roommates  = Person.roommate_list()
    @roommates  = Person.roommate_list(@person.id)

    @column_names = Person.column_names

    @roommate1 = Person.get_roommate(@person.roommate_id1)
    @roommate2 = Person.get_roommate(@person.roommate_id2)

    # get a hash of notes where key is note type
    # and value is array note objects
    notes = Person.get_notes(@person)

    # get the paramaters to be diplayed
    @notes_hash = Hash.new
    @params = Array.new
    @confirmation_flag = params[:confirmation]
    if (@confirmation_flag.eql?('true'))
      notes['confirmation'].nil? ?
        @notes_hash['confirmation'] = {} :
        @notes_hash['confirmation'] = notes['confirmation']
        @params = Person.show_confirmation(@person, @occupancy_by_id, @prices)
      #PersonMailer.registration_confirmation(@person,@params,@notes_hash).deliver
    else
      @notes_hash = notes
      @params = Person.show_person(@person, @occupancy_by_id, @prices)
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @person }
    end
  end

  # GET /people/new
  # GET /people/new.json
  def new
    @person = Person.new
    #@roommates = []
    #@roommates  = Person.roommate_list()
    @roommates  = Person.roommate_list(nil)

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @person }
    end
  end

  # GET /people/1/edit
  def edit
    @person = Person.find(params[:id])
   #render :text=>"in edit: #{@person.first_name}: #{@person.registration_status}"
   #return
    #@roommates  = Person.roommate_list()
    @roommates  = Person.roommate_list(@person.id)
    @note_hash = Person.get_notes(@person)

    @notes = @person.notes
#    @notes.gsub!(/\r\n/xx)
#    @header = "testit"
#    name = "#{@person.first_name} #{@person.last_name}"
#    phone = "#{@person.phone}"
#    email = "#{@person.email}"
#    notes = "#{@person.notes}"
#    notes.gsub!(/\r\n/, "\n")
#    arr = Array.new
#    csv_file = "/Users/snorman/Rails/registration/notes/test.out"
#    f = File.new(csv_file, 'w')
#    f.puts(name)
#    f.puts("\tphone: #{phone}")
#    f.puts("\temail: #{email}")
#    f.puts("\tnotes: #{notes}")
#    #arr.push(col1)
#    #arr.push(col2)
#    #arr.push(@notes)
#    # str = arr.join(",")
#    #f.puts(str)
#    f.close
#    render :text=>"text: #{@notes}"
#    return
    
  end

  # POST /people
  # POST /people.json
  def create

    #@person = Person.new(params[:person])
    @roommates  = Person.roommate_list(nil) 

    person_params = params[:person]
    params[:person] = Person.set_values(person_params, @prices)

    @person = Person.new(params[:person])

    respond_to do |format|
      if @person.save
        #PersonMailer.registration_confirmation(@person).deliver
        format.html { redirect_to @person, notice: 'Person was successfully created.' }
        format.json { render json: @person, status: :created, location: @person }
      else
        format.html { render action: "new" }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /people/1
  # PUT /people/1.json
  def update

    @person = Person.find(params[:id])
   #render :text=>"in update: #{@person.first_name}: #{@person.registration_status}"
   #return
    @roommates  = Person.roommate_list(@person.id)

    person_params = params[:person]
    params[:person] = Person.set_values(person_params, @prices)
    
    respond_to do |format|
      if @person.update_attributes(params[:person])
        format.html { redirect_to @person, notice: 'Person was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /people/1
  # DELETE /people/1.json
  def destroy
    @person = Person.find(params[:id])
    @person.destroy

    respond_to do |format|
      format.html { redirect_to people_url }
      format.json { head :no_content }
    end
  end

  def confirmation 

    confirmation_type = params[:confirmation_type]

    # send confirmation email
    @person = Person.find(params[:id])
    @roommates  = Person.roommate_list(@person.id)
    @roommate1 = Person.get_roommate(@person.roommate_id1)
    @roommate2 = Person.get_roommate(@person.roommate_id2)

    # get a hash of notes where key is note type
    # and value is array note objects
    notes = Person.get_notes(@person)

    # get the paramaters to be diplayed
    @notes_hash = Hash.new
    @params = Array.new
    @notes_hash['confirmation'] = notes['confirmation']
    @params = Person.show_confirmation(@person, @occupancy_by_id, @prices)

    if (confirmation_type.eql?('final'))
      PersonMailer.final_confirmation(@person,@params,@notes_hash,@wsr_logistics_pdf).deliver
    end
    if (confirmation_type.eql?('confirm'))
      PersonMailer.registration_confirmation(@person,@params,@notes_hash).deliver
    end


    # add email log note
    email_log_note = Person.generate_email_log(@person.id)
    @person.notes.push(email_log_note)

  end

  def xxconfirmation

    # send confirmation email
    #@person = Person.find(params[:id])
    #status = params[:status]
    #text = @person.notes
    #if ( status.eql?('initial'))
    #  @person = Person.find(params[:id]) 
    #end
    #@date_time = DateTime.now
    @date_time = DateTime.now.strftime("%F %T")

    @person = Person.find(params[:id]) 
    @notes = @person.notes

    params[:note] = Hash.new
    params[:note] = {:content=>"registration confirmation sent", 
                     :note_type=>"email_log",
                     :date_time=>@date_time,
		     :person_id=>@person.id} 

    note = Note.new(params[:note])
    @person.notes.push(note)
    @person.save

    
    #params = {:content=>#{@date_time: registration confirmation sent", :note_type=>"general"}}
    @params = Person.show_confirmation(@person, @occupancy_by_id, @prices)
    @roommate1 = Person.get_roommate(@person.roommate_id1)
    @roommate2 = Person.get_roommate(@person.roommate_id2)
    #@note_hash = Person.get_notes(@person)
#@note_hash = Hash.new

    PersonMailer.registration_confirmation(@person,@params, @roommate1, @roommate2).deliver

  end

  def initial_confirmation(person)

    person_hash = Hash.new
    person_hash['first_name'] = person.first_name
    return person_hash

  end

  def show_email_log

    @people = Person.find(:all, :order=>'last_name')

    @email_logs_arr = Array.new
    @email_logs_hash = Hash.new
 
    @people.each do |p|
      note_hash = Person.get_email_log(p)
      @email_logs_hash[p.id] = note_hash
      @email_logs_arr.push(note_hash)
    end

  end

  def test_template

#    @scholarship_applicants = Person.find(:all,:conditions=>'scholarship_applicant'=1);
#    render :text=>"in test_template"
#    return
#
#    @person = Person.find(params[:id]) 
#
#    @params = Person.get_confirmation(@person, @occupancy_by_id, @prices)
#
#    #@filtered_notes = Person.get_filtered_notes(@person, 'confirmation')
#    @filtered_notes = Person.get_notes(@person, 'confirmation')
#    render :text=>"tesit: #{@filtered_notes}"
#    return

  end

  def report

   report_type = params[:report_type]
   split_report = params[:split_report]

   if ( report_type.eql?('email_list')) 
    date_time = Time.now.strftime("%Y%m%d_%H%M") 
    fname = "WSR_email_list.#{date_time}.txt"
    full_path = Rails.root.join('reports', fname)
    #Person.create_email_list(full_path, @exclude_id)
    xx = Person.create_email_list(full_path, @exclude_id)
    render :text=>"asdf: #{xx}"
    return
   end

   if ( report_type.eql?('carpool'))
    date_time = Time.now.strftime("%Y%m%d_%H%M") 
    fname = "carpool_report.#{date_time}.csv"
    fname = "WSR_carpool.csv"
    full_path = Rails.root.join('reports', fname)
    Person.create_carpool_report(full_path, 'last_name')
   end

   if ( report_type.eql?('registration') )
    date_time = Time.now.strftime("%Y%m%d_%H%M") 
    fname = "final_registration.#{date_time}.csv"
    fname = "WSR_final_registration.csv"
    full_path = Rails.root.join('reports', fname)
    Person.create_final_registration_report(full_path, @occupancy_by_id)
   end

   if (report_type.eql?('roommate'))
    date_time = Time.now.strftime("%Y%m%d_%H%M") 
    #fname = "roommates.csv"
    fname = "roommate_report.#{date_time}.csv"
    full_path = Rails.root.join('reports', fname)
    Person.create_roommate_report(full_path, @occupancy_by_id)
   end

   if (report_type.eql?('stats'))
     # generate status report
     @date_time = DateTime.now.strftime("%F %T")
     @arr = Person.report(@facilitators, @initial_scholarship,split_report)
     @msg = "Report sent to: #{@email_list}"
     PersonMailer.registration_report(@email_list,@arr).deliver
   end

   if (report_type.eql?('send_all'))

#    # get a hash of notes where key is note type
#    # and value is array note objects
#    @person = Person.find(48)
#    @notes = Person.get_notes(@person)
##
#    # get the paramaters to be diplayed
#    @notes_hash = Hash.new
#    @params = Array.new
#    @notes_hash['confirmation'] = @notes['confirmation']
#    @params = Person.show_confirmation(@person, @occupancy_by_id, @prices)
#    #PersonMailer.registration_confirmation(@person,@params,@notes_hash).deliver
#     PersonMailer.final_confirmation(@person,@params,@notes_hash, @final_confirmation_pdf).deliver
#    # add email log note
#    email_log_note = Person.generate_email_log(@person.id)
#    @person.notes.push(email_log_note)
      #fname = "/Users/snorman/rails_tmp/wsr_registration/notes/test.out"
      #f = File.new(fname, 'w')
      # an array of facilitators id #
      people = Person.find(:all)
      count = 0

      #people = Array.new
      #xx = Person.find(56)
      #people.push(xx)
      #xx = Person.find(48)
      #people.push(xx)

      people.each do |p|
        next if @exclude_id.grep(p.id).length > 0
	next if p.registration_status.eql?('wait_list')
	#f.puts("#{p.first_name} #{p.last_name}: #{p.registration_status}")
	#next

        @person = p
        # get a hash of notes where key is note type
        # and value is array note objects
        @notes_hash = Hash.new
        @params = Array.new
        @notes = Person.get_notes(@person)
        @notes_hash['confirmation'] = @notes['confirmation']
        @params = Person.show_confirmation(@person, @occupancy_by_id, @prices)
        #PersonMailer.registration_confirmation(@person,@params,@notes_hash).deliver
        PersonMailer.final_confirmation(@person,@params,@notes_hash,@wsr_logistics_pdf).deliver
        # add email log note
        email_log_note = Person.generate_email_log(@person.id)
        @person.notes.push(email_log_note)
        ##PersonMailer.registration_confirmation(p,@params,{}).deliver
	sleep(30)
	#count = count+1
	#break if (count > 3)
      end
      #f.close
   end


  end

  def xxreport 

    #csv_file = "/Users/snorman/Rails/registration/notes/report.out"
    #f = File.new(csv_file, 'w')
    #header = "Name;Status;Paid;Balance;Notes"
    #header = "Name;Status;Paid;Balance"
    #f.puts(header)
    #sort_by = 'registration_status'
    sort_by = 'last_name'
    @people = Person.sort_by(sort_by) 
    @date_time = DateTime.now.strftime("%F %T")

    @arr = Array.new
    total_due = to_currency(Person.sum('total_due') - @facilitator_deduction)
    total_paid = to_currency(Person.sum('paid_amount') - @facilitator_deduction)
    total_balance_due = to_currency(Person.sum('balance_due'))
    available_scholarship = to_currency(@initial_scholarship + Person.sum('scholarship_donation'))
    total_scholarship_given = to_currency(Person.sum('scholarship_amount'))
    total_registered = Person.all.length
    registered_pending_count = Person.get_count('registration_status', 'pending')
    registered_paid_count = Person.get_count('registration_status', 'registered')
    registered_hold_count = Person.get_count('registration_status', 'hold')

    #total_paid = to_currency(Person.get_column_total('paid_amount', 'payment_status', 'paid'))
    #total_balance_due = Person.get_column_total('balance_due', 'payment_status', 'pending')
    #total_scholarship_amount = to_currency(Person.sum('scholarship_donation'))
    #registered_pending_count = Person.get_count('payment_status', 'pending')
    #registered_paid_count = Person.get_count('payment_status', 'paid')

    #@arr.push("Registration totals")
    @arr.push("Total due: #{total_due}")
    @arr.push("Total paid: #{total_paid}")
    @arr.push("Total balance due: #{total_balance_due}")
    @arr.push("Total available scholarships: #{available_scholarship}")
    @arr.push("Total scholarship given: #{total_scholarship_given}")
    @arr.push("Total registered: #{total_registered}")
    @arr.push("Total registered(pending): #{registered_pending_count}")
    @arr.push("Total registered(paid): #{registered_paid_count}")
    @arr.push("Total registered(hold): #{registered_hold_count}")
    @arr.push("******************************")
    @people.each do |p|
      next if (p.last_name.eql?('Vielbig'))
      next if (p.last_name.eql?('Bruni'))
      @arr.push("#{p.first_name} #{p.last_name}")
      @arr.push("Registration status: #{p.registration_status}")
      @arr.push("Paid amount: #{p.paid_amount}")
      if ( p.balance_due < 0 )
        @arr.push("Donation: #{p.balance_due.abs}")
      else
        @arr.push("Balance due: #{p.balance_due}")
      end
      @arr.push("--------------------")
    end
    str = ''
    #@arr.each do |stat|
    #  f.puts(stat)
    # end

    PersonMailer.registration_report(@email_list,@arr).deliver

    #f.close

  end

  def to_currency(num)

    sprintf("%s%.2f","$",num)

    #return "$".concat(num.to_s)

  end

end
