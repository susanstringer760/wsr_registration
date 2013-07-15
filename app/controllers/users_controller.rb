class UserController < ApplicationController
  UserMailer.registration_confirmation(@user).deliver
end
