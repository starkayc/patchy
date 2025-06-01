module Routes::Admin
  extend self

  struct FileinfoResponse
    include JSON::Serializable

    property successfull : Int32 = 0
    property failed : Int32 = 0
    @[JSON::Field(key: "successfullFiles")]
    property successfull_files : Hash(String, UFile) = {} of String => UFile
    @[JSON::Field(key: "failedFiles")]
    property failed_files : Array(String) = [] of String

    def initialize
    end

    def add_successfull(filename : String, fileinfo : UFile)
      @successfull = @successfull + 1
      successfull_files[filename] = fileinfo
    end

    def add_failed(filename : String)
      @failed = @failed + 1
      failed_files << filename
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

    res = FileinfoResponse.new

    req.files.each do |filename|
      filename = filename.to_s
      begin
        fileinfo = Database::Files.select(filename)
        if fileinfo
          res.add_successfull(filename, fileinfo)
        else
          res.add_failed(filename)
        end
      rescue ex
        LOGGER.error "Unknown error: #{ex.message}"
        ee 500, "Unknown error: #{ex.message}"
      end
    end

    res.to_json
  end
end
