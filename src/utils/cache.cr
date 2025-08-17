module Utils::Cache
  extend self
  Log = ::Log.for("filecache")

  FileCache = CONFIG.cache.enabled ? LRU.new : nil

  # Based on
  # https://git.nadeko.net/Fijxu/invidious/src/commit/0dd11b2e0fe00b0a9ccc68c38a69366e77c5e6d8/src/invidious/database/videos.cr#L37
  class LRU
    @max_size : Int32
    @max_allowed_filesize : Int32
    getter lru = {} of String => {fileinfo: Fileinfo, data: Bytes, filesize: Int64}
    @access = [] of String

    def initialize(@max_size = CONFIG.cache.max_size, @max_allowed_filesize = CONFIG.cache.max_allowed_filesize)
      if CONFIG.cache.enabled
        Log.info &.emit("using in memory LRU to store files smaller than #{(@max_allowed_filesize * 1000).humanize_bytes}")
        Log.info &.emit("maximum amount of files the cache can hold: #{@max_size}")
        Log.info &.emit("max bytes that the cache can hold: #{(@max_size * @max_allowed_filesize * 1000).humanize_bytes}")
      end
    end

    # TODO: Handle expire_time with a Job
    def set(fileinfo : Fileinfo, file : File, expire_time : Int32) : Nil
      file_size = file.size

      if file_size > @max_allowed_filesize &* 1000
        Log.trace &.emit("not caching '#{fileinfo.filename}', size too big to be cached, size: #{file_size.humanize_bytes}")
        return
      end

      slice = Bytes.new(file_size)
      file.read_fully(slice)
      self[fileinfo.filename] = {fileinfo: fileinfo, data: slice, filesize: file_size}
      Log.trace &.emit("inserted file '#{fileinfo.filename}' to memory")
    end

    def del(fileinfo : Fileinfo) : Nil
      self.delete(fileinfo.filename)
    end

    def get(fileinfo : Fileinfo) : Bytes?
      data = self[fileinfo.filename]
      if data
        Log.trace &.emit("retrieved file '#{fileinfo.filename}' from memory")
        return data[:data]
      else
        return nil
      end
    end

    private def [](key : String) : NamedTuple(fileinfo: Fileinfo, data: Slice(UInt8), filesize: Int64)?
      if @lru[key]?
        @access.delete(key)
        @access.push(key)
        @lru[key]
      else
        nil
      end
    end

    private def []=(key : String, value : NamedTuple(fileinfo: Fileinfo, data: Slice(UInt8), filesize: Int64)) : Array(String)
      if @lru.size >= @max_size
        lru_key = @access.shift
        @lru.delete(lru_key)
      end
      @lru[key] = value
      @access.push(key)
    end

    private def delete(key)
      if @lru[key]?
        @lru.delete(key)
        @access.delete(key)
      end
    end
  end

  def insert(fileinfo : Fileinfo, file_path : String) : Nil
    return if FileCache.nil?
    file = File.open(file_path)
    FileCache.as(LRU).set(fileinfo: fileinfo, file: file, expire_time: 14400)
    file.close
  end

  def delete(fileinfo : Fileinfo)
    return if FileCache.nil?
    FileCache.as(LRU).del(fileinfo)
  end

  def select(fileinfo : Fileinfo) : Slice(UInt8)?
    return if FileCache.nil?
    FileCache.as(LRU).get(fileinfo)
  end
end
