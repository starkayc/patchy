require "http/client"

module Routing::Misc
  extend self

  struct Stats
    include JSON::Serializable

    @[JSON::Field(key: "filesHosted")]
    property files_hosted : Int32
    @[JSON::Field(key: "maxUploadSize")]
    property max_upload_size : String
    @[JSON::Field(key: "thumbnailGeneration")]
    property thumbnail_generation : Bool
    @[JSON::Field(key: "filenameLength")]
    property filename_length : Int32
    @[JSON::Field(key: "alternativeDomains")]
    property alternative_domains : Array(String)

    def initialize
      @files_hosted = SQL.query_one("SELECT COUNT (filename) FROM files", as: Int32)
      @max_upload_size = CONFIG.size_limit.to_s
      @thumbnail_generation = CONFIG.generate_thumbnails
      @filename_length = CONFIG.filename_length
      @alternative_domains = CONFIG.alternative_domains
    end
  end

  def stats(env)
    env.response.content_type = "application/json"
    Stats.new.to_json
  end

  def sharex_config(env)
    host = env.request.headers["X-Forwarded-Host"]? || env.request.headers["Host"]?
    scheme = env.request.headers["X-Forwarded-Proto"]? || "http"
    env.response.content_type = "application/json"
    # So it's able to download the file instead of displaying it
    env.response.headers["Content-Disposition"] = "attachment; filename=\"#{host}.sxcu\""

    return %({
"Version": "14.0.1",
"DestinationType": "ImageUploader, FileUploader",
"RequestMethod": "POST",
"RequestURL": "#{scheme}://#{host}/upload",
"Body": "MultipartFormData",
"FileFormName": "file",
"URL": "{json:link}",
"DeletionURL": "{json:deleteLink}",
"ErrorMessage": "{json:error}"
})
  end

  def chatterino_config(env)
    host = env.request.headers["X-Forwarded-Host"]? || env.request.headers["Host"]?
    scheme = env.request.headers["X-Forwarded-Proto"]? || "http"
    env.response.content_type = "application/json"

    return %({
"requestUrl": "#{scheme}://#{host}/upload",
formField": "data",
imageLink": "{link}",
deleteLink": "{deleteLink}"
})
  end
end
