match 'auth/failure', controller: :omniauth, action: :omniauth_failure, via: [:get, :post]
match 'auth/:provider/callback', controller: :omniauth, action: :omniauth_callback, via: [:get, :post]
match 'auth/:provider', controller: :omniauth, action: :omniauth_login, via: [:get], as: :omniauth_signin
