require "uri/params/serializable"

module Routes::UserSettings
  extend self

  def set_cookie(name : String, domain : String?, user_settings : ::UserSettings) : HTTP::Cookie
    return HTTP::Cookie.new(
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
      new_user_settings = ::UserSettings.from_www_form(env.params.body.to_s)
      new_user_settings = self.parse_settings(new_user_settings)
      env.response.cookies["PREFS"] = self.set_cookie("PREFS", host, new_user_settings)
    rescue ex
      # TODO: Show error page if settings were unable to be parsed
      return env.redirect "/-/settings"
    end

    return env.redirect "/-/settings"
  end

  def parse_settings(new_user_settings : ::UserSettings) : ::UserSettings
    new_user_settings.filename_length = new_user_settings.filename_length.clamp(CONFIG.min_filename_length, CONFIG.max_filename_length)
    return new_user_settings
  end
end
