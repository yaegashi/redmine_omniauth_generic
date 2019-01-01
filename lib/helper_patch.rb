require 'application_helper'

module OmniauthHelperPatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable
    end
  end

  module InstanceMethods
    OMNIAUTH_BUTTON_ICONS = {
      developer: 'omniauth.png',
      azure_oauth2: 'azure.png',
    }

    OMNIAUTH_BUTTON_TEXTS = {
      developer: 'Developer',
      azure_oauth2: 'Azure AD',
    }

    def omniauth_button_icon(provider, args)
      a = args[0] || {}
      b = a[:button] || {}
      b[:icon] || OMNIAUTH_BUTTON_ICONS[provider] || 'omniauth.png'
    end

    def omniauth_button_text(provider, args)
      a = args[0] || {}
      b = a[:button] || {}
      b[:text] || OMNIAUTH_BUTTON_TEXTS[provider] || provider.to_s.humanize
    end
  end
end

ApplicationHelper.send(:include, OmniauthHelperPatch)
