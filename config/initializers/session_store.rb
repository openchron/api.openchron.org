# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_api_session',
  :secret      => '364ef7b743e030fb1427448244c92a9db7426b9318039a5a2d078e3b51479f9680a5cfcb1239c5a308653bd3a6850769a9cd1d5e6afa7bb60b97a91721806e09'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
