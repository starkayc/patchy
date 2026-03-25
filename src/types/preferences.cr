require "uri/params/serializable"

struct Preferences
  include JSON::Serializable
  include URI::Params::Serializable

  enum Theme
    Gruvbox
  end

  property theme : Theme = Theme::Gruvbox
end
