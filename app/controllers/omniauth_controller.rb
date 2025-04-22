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

  def omniauth_authorize_microsoft_graph(provider)
    args = OmniAuth::Builder.providers[provider] || [{}]
    options = args[0]
    ag = options[:authorized_member_groups]
    return true unless ag
    ag = [ag] unless ag.is_a?(Array)
    begin
      token = request.env['omniauth.auth'].credentials.token
      conn = Faraday.new(url: 'https://graph.microsoft.com') do |f|
        f.request :json
        f.response :json, parser_options: {object_class: OpenStruct}
        f.adapter Faraday.default_adapter
      end
      res = conn.post('/v1.0/me/getMemberObjects') do |req|
        req.headers = headers.merge({
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{token}",
        })
        req.body = {securityEnabledOnly: true}
      end
      if res.success?
        member_groups = res.body.value
        logger.info "OmniAuth member groups: #{member_groups.to_json}"
        ag.each do |g|
          return true if member_groups.include?(g)
        end
      else
        logger.error "OmniAuth Microsoft Graph error: #{res.status} #{res.body}"
        return false
      end
    rescue
      logger.error "OmniAuth Microsoft Graph error: #{$!.message}"
      return false
    end
  end

  def settings
    @settings ||= Setting.plugin_redmine_omniauth_generic
  end
end
