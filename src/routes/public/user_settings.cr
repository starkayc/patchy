require "uri/params/serializable"

module Routes::UserSettings
  extend self
  Log = ::Log.for(self)

  def set_cookie(name : String, domain : String?, user_settings : ::UserSettings) : HTTP::Cookie
    HTTP::Cookie.new(
      name: name,
      # domain: domain,
      value: URI.encode_www_form(user_settings.to_json),
      expires: Time.utc + 2.years,
      http_only: false,
      samesite: HTTP::Cookie::SameSite::Lax,
      path: "/"
    )
  end

  def update_settings(env : HTTP::Server::Context) : Nil
    host = Headers.host

    begin
      Log.trace &.emit("user settings body received", user_settings: env.params.body.to_s)
      new_user_settings = ::UserSettings.from_www_form(env.params.body.to_s)
      new_user_settings = parse_settings(new_user_settings)
      Log.trace &.emit("new user settings set", new_user_settings: new_user_settings.to_json)
      env.response.cookies["PREFS"] = set_cookie("PREFS", host, new_user_settings)
    rescue
      # TODO: Show error page if settings were unable to be parsed
      return env.redirect "/-/settings"
    end

    env.redirect "/-/settings"
  end

  def parse_settings(new_user_settings : ::UserSettings) : ::UserSettings
    new_user_settings.filename_length = new_user_settings.filename_length.clamp(CONFIG.min_filename_length, CONFIG.max_filename_length)

    new_user_settings
  end
end
