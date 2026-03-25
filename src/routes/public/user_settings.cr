require "uri/params/serializable"

module Routes::UserSettings
  extend self

  def set_cookie(name : String, domain : String?, preferences : Preferences) : HTTP::Cookie
    return HTTP::Cookie.new(
      name: name,
      # domain: domain,
      value: URI.encode_www_form(preferences.to_json),
      expires: Time.utc + 2.years,
      http_only: false,
      samesite: HTTP::Cookie::SameSite::Lax,
      path: "/"
    )
  end

  def update_settings(env : HTTP::Server::Context)
    host = Headers.host

    begin
      new_settings = Preferences.from_www_form(env.params.body.to_s)
      env.response.cookies["PREFS"] = self.set_cookie("PREFS", host, new_settings)
    rescue ex
      # TODO: Show error page if settings were unable to be parsed
      return env.redirect "/-/settings"
    end

    return env.redirect "/-/settings"
  end
end
