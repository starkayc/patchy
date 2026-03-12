module Handlers::Options
  extend self

  class CORSHeaders < Kemal::Handler
    only CONFIG.cors.paths, "GET"

    def call(env)
      return call_next(env) unless only_match?(env)
      env.response.headers["Access-Control-Allow-Origin"] = "*"
      call_next(env)
    end
  end

  def options(env : HTTP::Server::Context) : Nil
    env.response.headers["Access-Control-Allow-Origin"] = CONFIG.cors.access_control.allow_origin
    env.response.headers["Access-Control-Allow-Methods"] = CONFIG.cors.access_control.allow_methods
    env.response.headers["Access-Control-Allow-Headers"] = CONFIG.cors.access_control.allow_headers
    env.response.headers["Access-Control-Max-Age"] = CONFIG.cors.access_control.max_age
    env.response.status_code = 204
  end
end
