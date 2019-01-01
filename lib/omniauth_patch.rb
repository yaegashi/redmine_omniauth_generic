module OmniAuth
  class Builder
    def Builder.providers
      @@providers
    end
    def provider_patch(klass, *args, &block)
      @@providers ||= {}
      @@providers[klass] = args
      provider_original(klass, *args, &block)
    end
    alias provider_original provider
    alias provider provider_patch
  end
end
