module Routes::Views
  extend self

  def root(env)
    host = env.request.headers["X-Forwarded-Host"]? || env.request.headers["Host"]?
    scheme = env.request.headers["X-Forwarded-Proto"]? || "http"
    files_hosted = Database::Files.file_count

    render "src/views/index.ecr"
  end

  def chatterino(env)
    host = env.request.headers["X-Forwarded-Host"]? || env.request.headers["Host"]?
    scheme = env.request.headers["X-Forwarded-Proto"]? || "http"

    render "src/views/chatterino.ecr"
  end
end
