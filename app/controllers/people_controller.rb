class PeopleController < ApplicationController

  # GET /people
  # GET /people.json
  def index

  params[:sort_by] ?
    sort_by = params[:sort_by] :
    sort_by = 'last_name'

    # list of people
    @people = Person.sort_by(sort_by) 

    # hash of roommates where key is person id
    # and value is person name
    @roommate_hash = Person.roommate_hash()

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @people }
    end

  end

  # GET /people/1
  # GET /people/1.json
  def show

    @person = Person.find(params[:id])
    #@roommates  = Person.roommate_list()
    @roommates  = Person.roommate_list(@person.id)

    @column_names = Person.column_names

    @roommate1 = Person.get_roommate(@person.roommate_id1)
    @roommate2 = Person.get_roommate(@person.roommate_id2)
    @note_hash = Person.get_notes(@person)

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
                     :note_type=>"confirmation",
                     :date_time=>@date_time,
		     :person_id=>@person.id} 

    note = Note.new(params[:note])
    @person.notes.push(note)
    @person.save

    
    #params = {:content=>#{@date_time: registration confirmation sent", :note_type=>"general"}}
    @params = Person.get_confirmation(@person, @occupancy_by_id, @prices)
    @roommate1 = Person.get_roommate(@person.roommate_id1)
    @roommate2 = Person.get_roommate(@person.roommate_id2)
    #@note_hash = Person.get_notes(@person)
#@note_hash = Hash.new

    #PersonMailer.registration_confirmation(@person).deliver
    PersonMailer.registration_confirmation(@person,@params, @roommate1, @roommate2).deliver

  end

  def initial_confirmation(person)

    person_hash = Hash.new
    person_hash['first_name'] = person.first_name
    return person_hash

  end

  def test_template

    @person = Person.find(params[:id]) 

    @params = Person.get_confirmation(@person, @occupancy_by_id, @prices)

    #@filtered_notes = Person.get_filtered_notes(@person, 'confirmation')
    @filtered_notes = Person.get_notes(@person, 'confirmation')
    render :text=>"tesit: #{@filtered_notes}"
    return

  end

  def report 

    csv_file = "/Users/snorman/Rails/registration/notes/report.out"
    f = File.new(csv_file, 'w')
    #header = "Name;Status;Paid;Balance;Notes"
    header = "Name;Status;Paid;Balance"
    f.puts(header)
    #sort_by = 'registration_status'
    sort_by = 'last_name'
    @people = Person.sort_by(sort_by) 
    @date_time = DateTime.now.strftime("%F %T")

    @arr = Array.new
    total_due = to_currency(Person.sum('total_due'))
    total_paid = to_currency(Person.sum('paid_amount'))
    total_balance_due = to_currency(Person.sum('balance_due'))
    total_scholarship_amount = to_currency(Person.sum('scholarship_donation'))
    total_scholarship_given = to_currency(Person.sum('scholarship_amount'))
    #total_paid = to_currency(Person.get_column_total('paid_amount', 'payment_status', 'paid'))
    #total_balance_due = Person.get_column_total('balance_due', 'payment_status', 'pending')
    total_registered = Person.all.length
    registered_pending_count = Person.get_count('payment_status', 'pending')
    registered_paid_count = Person.get_count('payment_status', 'paid')
    #@arr.push("Registration totals")
    @arr.push("Total due: #{total_due}")
    @arr.push("Total paid: #{total_paid}")
    @arr.push("Total balance due: #{total_balance_due}")
    @arr.push("Total scholarship given: #{total_scholarship_given}")
    @arr.push("Total scholarship donated: #{total_scholarship_amount}")
    @arr.push("Total registered: #{total_registered}")
    @arr.push("Total registered(pending): #{registered_pending_count}")
    @arr.push("Total registered(paid): #{registered_paid_count}")
    @arr.push("******************************")
    @people.each do |p|
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
    @arr.each do |stat|
      f.puts(stat)
    end

    PersonMailer.registration_report(@email_list,@arr).deliver

    f.close

  end

  def to_currency(num)

    sprintf("%s%.2f","$",num)

    #return "$".concat(num.to_s)

  end

end
