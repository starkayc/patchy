module Utils::Cache
  extend self
  Log = ::Log.for("filecache")

  enum Type
    LRU
    Redis
  end

  @@cache : (LRU | RedisCache)? = nil

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
    @access = [] of String
    @lru = {} of String => CachedData

    def initialize(
      @max_size = CONFIG.cache.max_size,
      @max_allowed_filesize = CONFIG.cache.max_allowed_filesize,
    )
      if CONFIG.cache.enabled
        Log.info &.emit("using in memory LRU for caching")
        Log.info &.emit("files smaller than this size limit will be stored into the cache: '#{(@max_allowed_filesize * 1000).humanize_bytes}'")
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

    def set(fileinfo : Fileinfo, file : File, expire_time : UInt64?) : Nil
      filesize = file.size
      filename = fileinfo.filename

      slice = Bytes.new(filesize)
      file.read_fully(slice)
      expire_time ? (expires_at = Time.utc.to_unix + expire_time) : (expires_at = nil)
      cached = CachedData.new(fileinfo, slice, filesize, expires_at)

      self[filename] = cached
      Log.trace &.emit("inserted file '#{filename}' to cache")
    end

    def del(filename : String) : Nil
      self.delete(filename)
      Log.trace &.emit("deleted file '#{filename}' from cache")
    end

    def get(filename : String) : Bytes?
      cached = self[filename]
      if cached
        Log.trace &.emit("retrieved file '#{filename}' from cache")
        return cached.data
      else
        return
      end
    end

    def size : Int64
      return @lru.size.to_i64
    end

    def items
      return @lru
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

  # Based on
  # https://git.nadeko.net/Fijxu/invidious/src/commit/0dd11b2e0fe00b0a9ccc68c38a69366e77c5e6d8/src/invidious/database/videos.cr#L99
  class RedisCache
    @client : Redis::Client
    @max_allowed_filesize : Int32

    def initialize(
      @max_allowed_filesize = CONFIG.cache.max_allowed_filesize,
    )
      redis_url = CONFIG.cache.redis_url
      @client = begin
        Redis::Client.new(URI.parse(redis_url))
      rescue ex
        Log.fatal &.emit("failed to connect to the redis compatible database", error: ex.message)
        exit(1)
      end
      Log.info &.emit("using Redis compatible DB for caching")
      Log.info &.emit("connecting to Redis compatible DB")
      if @client.ping
        Log.info &.emit("#{"connected to Redis compatible DB"}#{redis_url.presence ? " at '#{redis_url}'" : nil}")
      end
      Log.info &.emit("files smaller than this size limit will be stored into the cache: '#{(@max_allowed_filesize * 1000).humanize_bytes}'")
    end

    def set(fileinfo : Fileinfo, file : File, expire_time : UInt64?)
      filename = fileinfo.filename
      filedata = file.gets_to_end

      begin
        @client.set(filename, filedata, ex: expire_time)
      rescue ex
        Log.error &.emit("failed to insert file '#{filename}' from cache", error: ex.message)
        return
      end

      Log.trace &.emit("inserted file '#{filename}' to cache")
    end

    def del(filename : String)
      @client.del(filename)
      Log.trace &.emit("deleted file '#{filename}' from cache")
    end

    def get(filename : String)
      begin
        cached = @client.get(filename)
      rescue ex
        Log.error &.emit("failed to retrieve file '#{filename}' from cache", error: ex.message)
        return
      end
      if cached
        Log.trace &.emit("retrieved file '#{filename}' from cache")
        cached.to_slice
      else
        return
      end
    end

    def size : Int64
      @client.dbsize
    end

    def items
      # TODO: Not implemented
      nil
    end
  end

  def init
    if CONFIG.cache.enabled
      case CONFIG.cache.type
      when Type::LRU
        @@cache = LRU.new
      when Type::Redis
        @@cache = RedisCache.new
      else
        @@cache = LRU.new
      end
    end
  end

  private def is_too_big_for_cache?(fileinfo : Fileinfo, file : File, max_allowed_filesize : Int32)
    filesize = file.size
    filename = fileinfo.filename

    if filesize > max_allowed_filesize &* 1000
      Log.debug &.emit("not caching '#{filename}', size too big to be cached", size: filesize.humanize_bytes)
      true
    else
      false
    end
  end

  def insert(fileinfo : Fileinfo, file_path : String, expire_time : UInt64? = nil) : Nil
    cache = @@cache
    return if cache.nil?
    file = File.open(file_path)
    return if is_too_big_for_cache?(fileinfo, file, CONFIG.cache.max_allowed_filesize)
    cache.set(fileinfo: fileinfo, file: file, expire_time: expire_time)
    file.close
  end

  def delete(fileinfo : Fileinfo) : Nil
    cache = @@cache
    return if cache.nil?
    filename = fileinfo.filename
    cache.del(filename)
  end

  def select(fileinfo : Fileinfo) : Slice(UInt8)?
    cache = @@cache
    return if cache.nil?
    filename = fileinfo.filename
    cache.get(filename)
  end

  def size
    return @@cache.try &.size
  end

  def items
    return @@cache.try &.items
  end
end
