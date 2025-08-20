module Utils::Cache
  extend self
  Log = ::Log.for("filecache")

  FileCache = CONFIG.cache.enabled ? LRU.new : nil

  struct CachedData
    include JSON::Serializable

    property fileinfo : Fileinfo
    property data : Bytes
    property filesize : Int64
    property expires_at : Int64?

    def initialize(
      @fileinfo,
      @data,
      @filesize,
      @expires_at,
    )
    end
  end

  # Based on
  # https://git.nadeko.net/Fijxu/invidious/src/commit/0dd11b2e0fe00b0a9ccc68c38a69366e77c5e6d8/src/invidious/database/videos.cr#L37
  class LRU
    @max_size : Int32
    @max_allowed_filesize : Int32
    getter lru = {} of String => CachedData
    @access = [] of String

    def initialize(
      @max_size = CONFIG.cache.max_size,
      @max_allowed_filesize = CONFIG.cache.max_allowed_filesize,
    )
      if CONFIG.cache.enabled
        Log.info &.emit("using in memory LRU to store files smaller than #{(@max_allowed_filesize * 1000).humanize_bytes}")
        Log.info &.emit("maximum amount of files the cache can hold: #{@max_size}")
        Log.info &.emit("max bytes that the cache can hold: #{(@max_size * @max_allowed_filesize * 1000).humanize_bytes}")
      end
      if clean_interval = CONFIG.cache.clean_interval
        spawn(name: {{ @type.name.stringify }}) do
          loop do
            self.cleaner
            sleep clean_interval.seconds
          end
        end
      end
    end

    def cleaner
      current_time = Time.utc.to_unix
      sample_size = (@lru.size * 0.25).ceil.to_i
      sample = @lru.sample(sample_size)

      sample.each do |filename, cached|
        if expires_at = cached.expires_at
          if expires_at < current_time
            self.del(filename)
            Log.trace &.emit("file '#{filename}', expired")
          end
        end
      end
    end

    def set(fileinfo : Fileinfo, file : File, expire_time : Int64?) : Nil
      filesize = file.size
      filename = fileinfo.filename

      if filesize > @max_allowed_filesize &* 1000
        Log.trace &.emit("not caching '#{filename}', size too big to be cached, size: #{filesize.humanize_bytes}")
        return
      end

      slice = Bytes.new(filesize)
      file.read_fully(slice)
      expire_time ? (expires_at = Time.utc.to_unix + expire_time) : (expires_at = nil)
      cached = CachedData.new(fileinfo, slice, filesize, expires_at)

      self[filename] = cached
      Log.trace &.emit("inserted file '#{filename}' to cache")
    end

    def del(filename : String) : Nil
      self.delete(filename)
    end

    def get(filename : String) : Bytes?
      cached = self[filename]
      if cached
        Log.trace &.emit("retrieved file '#{filename}' from cache")
        return cached.data
      else
        return nil
      end
    end

    private def [](key : String)
      if @lru[key]?
        @access.delete(key)
        @access.push(key)
        @lru[key]
      else
        nil
      end
    end

    private def []=(key : String, value) : Array(String)
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

  def insert(fileinfo : Fileinfo, file_path : String, expire_time : Int64? = nil) : Nil
    return if FileCache.nil?
    file = File.open(file_path)
    FileCache.as(LRU).set(fileinfo: fileinfo, file: file, expire_time: expire_time)
    file.close
  end

  def delete(fileinfo : Fileinfo)
    return if FileCache.nil?
    filename = fileinfo.filename
    FileCache.as(LRU).del(filename)
  end

  def select(fileinfo : Fileinfo) : Slice(UInt8)?
    return if FileCache.nil?
    filename = fileinfo.filename
    FileCache.as(LRU).get(filename)
  end
end
