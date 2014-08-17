# constants

# room prices
WsrRegistration::Application.config.prices = [364.00,235.00,195.00]

# occupancy
WsrRegistration::Application.config.occupancy_by_id = {'1'=>'Single','2'=>'Double', '3'=>'Triple' }
WsrRegistration::Application.config.occupancy_by_value = {'Single'=>'1','Double'=>'2', 'Triple'=>'3' }

# admin email
WsrRegistration::Application.config.email_list = "[admin@gmail.com]"

# initial scholarship amount
WsrRegistration::Application.config.initial_scholarship = 300.00 

# facilitators
facilitators = Array.new
facilitators.push(Person.find_by_last_name('[last_name]'))
facilitators.push(Person.find_by_last_name('[last_name]'))
WsrRegistration::Application.config.facilitatiors = facilitators 

# array of people to exclude when sending out confirmation email
exclude_id = Array.new
facilitators.each do |f|
  exclude_id.push(f.id)
end
WsrRegistration::Application.config.exclude_id = exclude_id 

# final confirmation pdf
WsrRegistration::Application.config.final_confirmation_pdf = "[path for pdf]"

