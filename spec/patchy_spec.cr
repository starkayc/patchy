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
  file = File.open("./spec/empty.jpg")
  file_size = file.size
  expire_time = 1440

  describe "#set" do
    it "adds file to cache" do
      cache.set(MockFileInfo, file, expire_time)
      file.rewind
      cached = cache.lru["AAA"]
      cached[:fileinfo].should eq(MockFileInfo)
      cached[:data].should eq(file.getb_to_end)
      cached[:filesize].should eq(file_size)
    end
  end

  describe "#get" do
    data = cache.get(MockFileInfo)
    file.rewind
    data.should eq(file.getb_to_end)
  end

  describe "#del" do
  end
end
