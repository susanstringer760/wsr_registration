class NotesController < ApplicationController
  # GET /notes
  # GET /notes.json
  def index

    filter_by = params[:filter_by]
    @person = Person.find(params[:person_id])
    @notes = @person.notes

    #@filtered_notes = Array.new
    #@notes.each do |n|
    #  @filtered_notes.push(n) if (filter_by.eql?(n.note_type))
    #end
    @filtered_notes = Person.get_filtered_notes(@person, filter_by)

    @roommate_hash = Person.roommate_hash

    #@notes = Note.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @notes }
    end
  end

  # GET /notes/1
  # GET /notes/1.json
  def show
    @note = Note.find(params[:id])
    @person = Person.find(@note.person_id)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @note }
    end
  end

  # GET /notes/new
  # GET /notes/new.json
  def new

    #@note = Note.new
    @person = Person.find(params[:person_id])
    @note = @person.notes.build

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @note }
    end
  end

  # GET /notes/1/edit
  def edit
    #@note = Note.find(params[:id])
    @person = Person.find(params[:person_id])
    @note = @person.notes.find(params[:id])
  end

  # POST /notes
  # POST /notes.json
  def create

    @person = Person.find(params[:note][:person_id])
    params[:note][:date_time] = Time.now 
    params[:note][:content].gsub!(/\r\n/, ", ")
    @note = @person.notes.build(params[:note])

    respond_to do |format|
      if @note.save
        format.html { redirect_to @note, notice: 'Note was successfully created.' }
        format.json { render json: @note, status: :created, location: @note }
      else
        format.html { render action: "new" }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /notes/1
  # PUT /notes/1.json
  def update

    @person = Person.find(params[:note][:person_id])
    @note = @person.notes.find(params[:id])

    respond_to do |format|
      if @note.update_attributes(params[:note])
        format.html { redirect_to @note, notice: 'Note was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /notes/1
  # DELETE /notes/1.json
  def destroy

    @note = Note.find(params[:id])
    @note.destroy

    respond_to do |format|
      #format.html { redirect_to notes_url }
      format.html { redirect_to edit_person_path(:id=>@note.person_id) }
      format.json { head :no_content }
    end
  end
end
