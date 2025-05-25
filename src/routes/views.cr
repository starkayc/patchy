module Routes::Views
  extend self

  def root(env)
    host = env.request.headers["X-Forwarded-Host"]? || env.request.headers["Host"]?
    scheme = env.request.headers["X-Forwarded-Proto"]? || "http"
    files_hosted = Database::Files.file_count

    templated "index"
  end

  def uploader_configs(env)
    host = env.request.headers["X-Forwarded-Host"]? || env.request.headers["Host"]?
    scheme = env.request.headers["X-Forwarded-Proto"]? || "http"

    templated "uploader_configs"
  end
end
