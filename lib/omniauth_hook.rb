class RedmineOmniauthViewListener < Redmine::Hook::ViewListener
  render_on :view_account_login_bottom, partial: 'omniauth/signin'
end
