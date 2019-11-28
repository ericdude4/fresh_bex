import Config

# Client ID and secret are required
# Configure fresh bex globaly as follows. Keep in mind that your access token will expire...
# FreshBex chooses to remain agnositc to authorization, so that the user can keep control over this.
# I really only support setting config authorization tokens to make testing easier

# config :fresh_bex,
#   client_id: 1234asdf1234,
#   client_secret: asdf1234asdf,
#   redirect_uri: http://example.com/integrations/install/fresh-books,
#   oauth_2_access_token: %OAuth2.AccessToken{},
#   account_id: 12341234

import_config "#{Mix.env()}.exs"
