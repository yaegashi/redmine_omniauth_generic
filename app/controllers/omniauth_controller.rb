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
    provider = params[:provider].to_sym
    uid = request.env['omniauth.auth'].uid
    info = request.env['omniauth.auth'].info
    logger.info "OmniAuth authenticated: #{provider} #{uid} #{info.to_json}"
    authorize_method = "omniauth_authorize_#{provider}"
    if respond_to?(authorize_method) && !send(authorize_method, provider)
      flash['error'] = l('omniauth.error.authorization_failure')
      redirect_to signin_path
      return
    end
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

  def omniauth_authorize_azure_oauth2(provider)
    args = OmniAuth::Builder.providers[provider] || [{}]
    options = args[0]
    ag = options[:authorized_member_groups]
    return true unless ag
    ag = [ag] unless ag.is_a?(Array)
    mg = request.env['omniauth.auth'].extra.member_groups || []
    logger.info "OmniAuth member groups: #{mg.to_json}"
    ag.each do |g|
      return true if mg.include?(g)
    end
    return false
  end

  def settings
    @settings ||= Setting.plugin_redmine_omniauth_generic
  end
end
