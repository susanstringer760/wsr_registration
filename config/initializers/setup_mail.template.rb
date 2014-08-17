ActionMailer::Base.smtp_settings = {  
  :address              => "smtp.gmail.com",  
  :port                 => 587,  
  :domain               => "@gmail.com",  
  :user_name            => "[admin]@gmail.com",  
  :password             => "[password]!",  
  :authentication       => "plain",  
  :enable_starttls_auto => true  
}  
require Rails.root.join('lib', 'development_mail_interceptor')
ActionMailer::Base.default_url_options[:host] = "localhost:3000"  
Mail.register_interceptor(DevelopmentMailInterceptor) if Rails.env.development?
