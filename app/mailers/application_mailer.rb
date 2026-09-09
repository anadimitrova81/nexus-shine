class ApplicationMailer < ActionMailer::Base
  default from: -> { Mailing::Config.from }
  layout "mailer"
end
