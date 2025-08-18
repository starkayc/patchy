module Routes::Admin
  extend self

  struct DeletionResponse
    include JSON::Serializable

    property successfull : Int32 = 0
    property failed : Int32 = 0
    @[JSON::Field(key: "successfullFiles")]
    property successfull_files : Array(String) = [] of String
    @[JSON::Field(key: "failedFiles")]
    property failed_files : Array(Hash(String, String?)) = [] of Hash(String, String?)

    def initialize
    end

    def add_successful(filename : String) : Array(String)
      @successfull = @successfull + 1
      successfull_files << filename
    end

    def add_failed(failed_file : Hash(String, String | Nil)) : Array(Hash(String, String | Nil))
      @failed = @failed + 1
      failed_files << failed_file
    end
  end

  struct DeletionRequest
    include JSON::Serializable

    property files : Array(String)
  end

  # /api/admin/delete
  # curl -X POST -H "Content-Type: application/json" -H "X-Api-Key: asd" http://localhost:8080/api/admin/delete -d '{"files": ["j63"]}' | jq
  def delete_file(env : HTTP::Server::Context) : String?
    begin
      req = DeletionRequest.from_json(env.params.json.to_json)
    rescue ex : JSON::SerializableError
      Log.error &.emit("failed to parse JSON", error: ex.message)
      ee 400, "Failed to parse JSON"
    end

    res = DeletionResponse.new

    req.files.each do |filename|
      filename = filename.to_s
      begin
        file_deleted = Operations::Deletion.delete_file(filename, false)
        if file_deleted
          res.add_successful(filename)
        end
      rescue ex
        res.add_failed({filename => ex.message})
      end
    end

    res.to_json
  end
end
