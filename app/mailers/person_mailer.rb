class PersonMailer < ActionMailer::Base

  #default from: "from@example.com"
  #default :from => "susanstringer760@gmail.com"
  default :from => "wsr.serenity@gmail.com"

  #def registration_confirmation(person, params, roommate1, roommate2)
  def final_confirmation(person, params,notes_hash, attachment_fname)

     @person = person
     @params = params
     @notes_hash = notes_hash
     basename=File.basename(attachment_fname)
     cc_to = "susanstringer760@comcast.net"

     #mail.attachments['WSR_final_confirmation.pdf'] = {:mime_type => 'application/pdf',
     #                               :content => File.read('/Users/snorman/rails_tmp/wsr_registration/reports/WSR_final_confirmation.pdf')}
     mail.attachments[basename] = {:mime_type => 'application/pdf',
                                    :content => File.read(attachment_fname)}

     mail(:to=> @person.email, :cc=>"susanstringer760@comcast.net", :subject => "WSR Confirmation for #{@person.first_name} #{@person.last_name}")

  end

  def registration_confirmation(person, params,notes_hash)

     @person = person
     @params = params
     @notes_hash = notes_hash
     #@roommate1 = roommate1
     #@roommate2 = roommate2
     cc_to = "susanstringer760@comcast.net"


     #mail(:to=> @person.email, :subject => "WSR Confirmation")
     #mail(:to=> @person.email, :cc=>cc_to, :subject => "WSR Confirmation")
     mail(:to=> @person.email, :cc=>"susanstringer760@comcast.net", :subject => "WSR Confirmation for #{@person.first_name} #{@person.last_name}")

  end

  def registration_report(email_list,arr)

     @email_list = email_list
     @arr = arr

     mail(:to=> @email_list, :subject => "WSR Stats")

  end

end
