module Routes::Admin
  extend self

  struct FileinfoResponse
    include JSON::Serializable

    property successfull : Int32
    property failed : Int32
    @[JSON::Field(key: "successfullFiles")]
    property successfull_files : Hash(String, UFile)
    @[JSON::Field(key: "failedFiles")]
    property failed_files : Array(String)

    def initialize(sf : Hash(String, UFile), ff : Array(String))
      @successfull = sf.size
      @failed = ff.size
      @successfull_files = sf
      @failed_files = ff
    end
  end

  struct FileinfoRequest
    include JSON::Serializable

    property files : Array(String)
  end

  # /api/admin/fileinfo
  # curl -X POST -H "Content-Type: application/json" -H "X-Api-Key: asd" http://localhost:8080/api/admin/fileinfo -d '{"files": ["j63"]}' | jq
  def retrieve_file_info(env)
    begin
      req = FileinfoRequest.from_json(env.params.json.to_json)
    rescue ex : JSON::SerializableError
      LOGGER.error("Failed to parse JSON: #{ex.message}")
      ee 400, "Failed to parse JSON"
    end

    successfull_files = {} of String => UFile
    failed_files = [] of String

    req.files.each do |filename|
      filename = filename.to_s
      begin
        fileinfo = Database::Files.select(filename)
        if fileinfo
          successfull_files[filename] = fileinfo
        else
          failed_files << filename
        end
      rescue ex
        LOGGER.error "Unknown error: #{ex.message}"
        ee 500, "Unknown error: #{ex.message}"
      end
    end

    res = FileinfoResponse.new(successfull_files, failed_files)
    res.to_json
  end
end
