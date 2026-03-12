module Routes::Admin
  extend self

  struct CachedFilesResponse
    include JSON::Serializable

    @[JSON::Field(key: "cachedFiles")]
    property cached_files : Int32 = Utils::Cache.files.size
    @[JSON::Field(key: "memoryUsageBytes")]
    property memory_usage_bytes : Int32 = 0
    @[JSON::Field(key: "memoryUsageHuman")]
    property memory_usage_human : String? = nil
    property files : Array(String) = [] of String

    def initialize
      if files = Utils::Cache.files
        files.each do |filename, filesize|
          @files << filename
          @memory_usage_bytes = @memory_usage_bytes + filesize
          @memory_usage_human = @memory_usage_bytes.humanize_bytes
        end
      end
    end
  end

  # /-/api/admin/cachedfiles
  # curl -X GET -H "X-Api-Key: asd" http://localhost:8080/api/admin/cachedfiles | jq
  def cached_files(env : HTTP::Server::Context) : String?
    msg EndpointDisabled.new.message if !CONFIG.cache.enabled
    CachedFilesResponse.new.to_json
  end
end
