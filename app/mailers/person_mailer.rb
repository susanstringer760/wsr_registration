class PersonMailer < ActionMailer::Base

  #default from: "from@example.com"
  default :from => "susanstringer760@comcast.net"

  def registration_confirmation(person, params, roommate1, roommate2)

     @person = person
     @params = params
     @roommate1 = roommate1
     @roommate2 = roommate2

     mail(:to=> @person.email, :subject => "WSR Confirmation")

  end


  def rregistration_confirmation(person)

     @person = person

     #mail(:to=> @person.email, :subject => "WSR Confirmation")
     #mail(:to => "#{person.first_name} <#{person.email}>", :subject => "Registered")

  end


end
