require "./spec_helper"

MockFileInfo = Fileinfo.new
MockFileInfo.original_filename = "empty.jpg"
MockFileInfo.filename = "AAA"
MockFileInfo.extension = ".jpg"
MockFileInfo.uploaded_at = Time.utc.to_unix
MockFileInfo.ip = "127.0.0.1"
MockFileInfo.delete_key = "AAA"
MockFileInfo.thumbnail = nil

describe Utils::Cache::LRU do
  cache = Utils::Cache::LRU.new
  describe "#insert" do
    file = File.open("./spec/empty.jpg")
    it "add file to cache" do
      cache.set(MockFileInfo, file, 1440)
      cache.lru["AAA"]
    end
  end
end
