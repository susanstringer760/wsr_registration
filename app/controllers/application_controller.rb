class ApplicationController < ActionController::Base
  protect_from_forgery

  #before_filter :set_prices
  #before_filter :set_occupancy
  #before_filter :report_email
  before_filter :set_constants

  protected

  def set_constants

    # room rates
    @prices = Hash.new
    @prices[1] = 364.00
    @prices[2] = 235.00 
    @prices[3] = 195.00 

    # occupancy mapping
    @occupancy_by_id = {'1'=>'Single','2'=>'Double', '3'=>'Triple' }
    @occupancy_by_value = {'Single'=>'1','Double'=>'2', 'Triple'=>'3' }

    # report recipients
    @email_list = "sanityhasreturned@gmail.com,sensabama@aol.com,susanstringer760@comcast.net,josiew1158@gmail.com"
    #@email_list = "susanstringer760@comcast.net, sensabama@aol.com"
    #@email_list = "susanstringer760@gmail.com"

    # base scholarship amount
    @initial_scholarship = 300.00

    # amount for facilitators
    @facilitators = Array.new
    @facilitators.push(Person.find_by_last_name('Vielbig'))
    @facilitators.push(Person.find_by_last_name('Bruni'))

    # array of people to exclude when sending out confirmation email
    @exclude_id = Array.new
    @facilitators.each do |f|
      @exclude_id.push(f.id)
    end
    tmp = Person.find(:all, :conditions=>{:last_name=>'Daily'})
    @exclude_id.push(tmp[0])

    @final_confirmation_pdf = "/Users/snorman/rails_tmp/wsr_registration/reports/WSR_final_confirmation.pdf"


  end

#  def set_prices() 
#    @prices = Hash.new
#    @prices[1] = 364 
#    @prices[2] = 235 
#    @prices[3] = 195 
#  end 
#
#  def set_occupancy
#    @occupancy_by_id = {'1'=>'Single','2'=>'Double', '3'=>'Triple' }
#    @occupancy_by_value = {'Single'=>'1','Double'=>'2', 'Triple'=>'3' }
#  end
#
#  def report_email
#    @email_list = "sanityhasreturned@gmail.com,sensabama@aol.com,susanstringer760@comcast.net"
#    #@email_list = "susanstringer760@comcast.net, snorman@ucar.edu"
#  end

end
