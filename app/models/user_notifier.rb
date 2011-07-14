class UserNotifier < ActionMailer::Base
  def forgot_password(user)
    setup_email(user)
    @subject    += 'Reset Password'
    @body[:url]  = "http://school1.pimcloud.com/user/reset_password/#{user.reset_password_code}"
  end

  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "info@kunalinfotech.net"
      @subject     = "[School Cloud] "
      @sent_on     = Time.now
      @body[:user] = user
    end
end