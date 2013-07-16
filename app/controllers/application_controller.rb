class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :set_prices
  before_filter :set_occupancy
  before_filter :report_email

  protected

  def set_prices() 
    @prices = Hash.new
    @prices[1] = 364 
    @prices[2] = 235 
    @prices[3] = 195 
  end 

  def set_occupancy
    @occupancy_by_id = {'1'=>'Single','2'=>'Double', '3'=>'Triple' }
    @occupancy_by_value = {'Single'=>'1','Double'=>'2', 'Triple'=>'3' }
  end

  def report_email
    @email_list = "sanityhasreturned@gmail.com,sensabama@aol.com,susanstringer760@comcast.net"
    #@email_list = "susanstringer760@comcast.net, snorman@ucar.edu"
  end

end
