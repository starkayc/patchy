require "uri/params/serializable"

struct UserSettings
  include JSON::Serializable
  include URI::Params::Serializable

  property filename_length : Int32 = CONFIG.filename_length
end
