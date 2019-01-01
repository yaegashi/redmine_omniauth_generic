class OmniauthController < AccountController

  def omniauth_failure
    flash['error'] = "#{l('omniauth.error.authentication_failure')}: #{params[:message]}"
    redirect_to signin_path
  end

  def omniauth_login
    flash['error'] = "#{l('omniauth.error.unknown_provider')}: #{params[:provider]}"
    redirect_to signin_path
  end

  def omniauth_callback
    if !settings['enabled']
      flash['error'] = l('omniauth.error.disabled')
      redirect_to signin_path
      return
    end
    info = request.env['omniauth.auth'].info
    user = User.joins(:email_addresses)
               .where('email_addresses.address' => info['email'], 'email_addresses.is_default' => true)
               .first_or_initialize
    if user.new_record?
      if !settings['auto_registration']
        flash['error'] = l('omniauth.error.authentication_failure')
        redirect_to signin_path
        return
      end
      user.firstname = info['first_name']
      user.lastname = info['last_name']
      user.mail = info['email']
      user.login = info['nickname'] || info['email']
      user.random_password
      user.register
      register_automatically(user) do
        onthefly_creation_failed(user)
      end
      return
    end
    if user.active?
      successful_authentication(user)
      return
    end
    account_pending
  end

  def settings
    @settings ||= Setting.plugin_redmine_omniauth_generic
  end
end
