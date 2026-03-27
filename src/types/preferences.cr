require "uri/params/serializable"

struct Preferences
  include JSON::Serializable
  include URI::Params::Serializable

  property theme : String = "Gruvbox"
end
