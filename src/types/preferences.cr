require "uri/params/serializable"

struct UserSettings
  include JSON::Serializable
  include URI::Params::Serializable

  module BoolMissingAsFalseConverter
    def self.from_www_form(params : URI::Params, key : String) : Bool
      params[key]? == "on" || params[key]? == "true" || params[key]? == "1"
    end
  end

  property filename_length : Int32 = CONFIG.uploads.filename_length
  @[URI::Params::Field(converter: BoolMissingAsFalseConverter)]
  property show_file_directly : Bool = CONFIG.default_user_settings.show_file_directly
end
