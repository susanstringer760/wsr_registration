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

  def registration_report(email_list,arr)

     @email_list = email_list
     @arr = arr

     mail(:to=> @email_list, :subject => "WSR Stats")

  end



  def rregistration_confirmation(person)

     @person = person

     #mail(:to=> @person.email, :subject => "WSR Confirmation")
     #mail(:to => "#{person.first_name} <#{person.email}>", :subject => "Registered")

  end


end
