module Routes::Admin
  extend self

  struct DeletionResponse
    include JSON::Serializable

    property successfull : Int32
    property failed : Int32
    @[JSON::Field(key: "successfullFiles")]
    property successfull_files : Array(String)
    @[JSON::Field(key: "failedFiles")]
    property failed_files : Array(String)

    def initialize(sf : Array(String), ff : Array(String))
      @successfull = sf.size
      @failed = ff.size
      @successfull_files = sf
      @failed_files = ff
    end
  end

  struct DeletionRequest
    include JSON::Serializable

    property files : Array(String)
  end

  # /api/admin/delete
  # curl -X POST -H "Content-Type: application/json" -H "X-Api-Key: asd" http://localhost:8080/api/admin/delete -d '{"files": ["j63"]}' | jq
  def delete_file(env)
    begin
      req = DeletionRequest.from_json(env.params.json.to_json)
    rescue ex : JSON::SerializableError
      LOGGER.error("Failed to parse JSON: #{ex.message}")
      ee 400, "Failed to parse JSON"
    end

    successfull_files = [] of String
    failed_files = [] of String

    req.files.each do |filename|
      filename = filename.to_s
      begin
        file_deleted = OP::Delete.delete_file(filename)
        if file_deleted
          successfull_files << filename
        else
          failed_files << filename
        end
      rescue ex
        LOGGER.error("Unknown error: #{ex.message}")
        ee 500, "Unknown error"
      end
    end

    res = DeletionResponse.new(successfull_files, failed_files)
    res.to_json
  end
end
