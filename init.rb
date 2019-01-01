require 'redmine'
require_dependency 'helper_patch'
require_dependency 'omniauth_hook'
require_dependency 'omniauth_patch'

Redmine::Plugin.register :redmine_omniauth_generic do
  name 'Redmine OmniAuth generic plugin'
  author 'YAEGASHI Takeshi'
  description 'Authentication/registration plugin with verified OmniAuth strategy providers'
  version '0.1'
  url 'https://github.com/yaegashi/redmine_omniauth_generic'
  author_url 'https://github.com/yaegashi'

  settings default: {
    enabled: false,
    auto_registration: false,
    announcement: '',
  }, partial: 'settings/omniauth_settings'
end

OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  Dir.glob(File.join(File.dirname(__FILE__), 'config/providers/*')).sort.each do |path|
    if File.file?(path)
      eval(File.read(path), binding, path)
    end
  end
end
