class ApplicationController < ActionController::Base

  protect_from_forgery

  before_filter :set_constants

  protected

  def set_constants

    # room prices
    @prices = WsrRegistration::Application.config.prices
    
    # occupancy
    @occupancy_by_id = WsrRegistration::Application.config.occupancy_by_id
    @occupancy_by_value = WsrRegistration::Application.config.occupancy_by_value
    
    # report email list
    @email_list = WsrRegistration::Application.config.email_list

    # admin email
    @admin_email = WsrRegistration::Application.config.admin_email
    @admin_password = WsrRegistration::Application.config.admin_password

    # initial scholarship amount
    @initial_scholarship = WsrRegistration::Application.config.initial_scholarship
    
    # facilitators
    @facilitators = Array.new
    @facilitators_last_name = WsrRegistration::Application.config.facilitators_last_name
    @facilitators_last_name.each do |name|
      @facilitators.push(Person.find_by_last_name(name))
    end
    
    # array of people to exclude when sending out confirmation email
    @exclude_id = Array.new
    @facilitators.each do |f|
      @exclude_id.push(f.id)
    end
    #@exclude_id = WsrRegistration::Application.config.exclude_id

    @final_confirmation_pdf = WsrRegistration::Application.config.final_confirmation_pdf

    @csv_fname = WsrRegistration::Application.config.csv_fname

  end

end
