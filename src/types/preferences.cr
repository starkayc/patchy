require "uri/params/serializable"

struct UserSettings
  include JSON::Serializable
  include URI::Params::Serializable

  property theme : String = "Gruvbox"
end
