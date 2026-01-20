# Be sure to restart your server when you modify this file.

# Configure session store to not require secure cookies when not using SSL.
# This prevents warnings about insecure cookies when SSL is not being used.
# The secure flag will be set based on config.force_ssl in each environment file.
Rails.application.config.session_store :cookie_store,
  key: '_vendi_session',
  secure: false, # Will be overridden by force_ssl if enabled
  same_site: :lax

# Configure ActionDispatch cookies to not require SSL when not using HTTPS.
# This prevents warnings about insecure cookies.
Rails.application.config.action_dispatch.cookies_serializer = :json
