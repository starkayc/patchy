module Routes::Admin
  extend self

  struct FileinfoResponse
    include JSON::Serializable

    property successfull : Int32 = 0
    property failed : Int32 = 0
    @[JSON::Field(key: "successfullFiles")]
    property successfull_files : Hash(String, Fileinfo) = {} of String => Fileinfo
    @[JSON::Field(key: "failedFiles")]
    property failed_files : Array(String) = [] of String

    def initialize
    end

    def add_successfull(filename : String, fileinfo : Fileinfo) : Fileinfo
      @successfull = @successfull + 1
      successfull_files[filename] = fileinfo
    end

    def add_failed(filename : String) : Array(String)
      @failed = @failed + 1
      failed_files << filename
    end
  end

  struct FileinfoRequest
    include JSON::Serializable

    property files : Array(String)
  end

  # /-/api/admin/fileinfo
  # curl -X POST -H "Content-Type: application/json" -H "X-Api-Key: asd" http://localhost:8080/-/api/admin/fileinfo -d '{"files": ["j63"]}' | jq
  def retrieve_file_info(env : HTTP::Server::Context) : String?
    begin
      req = FileinfoRequest.from_json(env.params.json.to_json)
    rescue ex : JSON::SerializableError
      Log.error &.emit("failed to parse JSON", error: ex.message)
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
        Log.error &.emit("unknown error", error: ex.message)
        ee 500, "Unknown error"
      end
    end

    res.to_json
  end
end
