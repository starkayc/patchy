module Utils::Cache
  extend self
  Log = ::Log.for("filecache")

  enum Type
    LRU
    Redis
  end

  @@cache : (LRU | RedisCache)? = nil
  # Variable that keeps track of the file sizes inserted into the cache
  @@files : Hash(String, Int64) = {} of String => Int64

  class LRU
    @cache : LRUCache(Bytes)
    @max_size : Int32
    @max_allowed_filesize : Int32

    def initialize(
      @max_size = CONFIG.cache.max_size,
      @max_allowed_filesize = CONFIG.cache.max_allowed_filesize,
    )
      @cache = LRUCache(Bytes).new(max_size: @max_size, clean_interval: 1.second)
      Log.info &.emit("using in memory LRU for caching")
      Log.info &.emit("files smaller than this size limit will be stored into the cache: '#{(@max_allowed_filesize * 1000).humanize_bytes}'")
      Log.info &.emit("maximum amount of files the cache can hold: #{@max_size}")
      Log.info &.emit("max bytes that the cache can hold: #{(@max_size * @max_allowed_filesize * 1000).humanize_bytes}")
    end

    def set(filename : String, filedata : Bytes, expire_time : UInt64?) : Nil
      @cache.set(filename, filedata, expire_time)
    end

    def get(filename : String) : Bytes?
      @cache.get(filename)
    end

    def del(filename : String) : Nil
      @cache.del(filename)
    end

    def size
      @cache.size
    end

    def items
      @cache.items
    end

    def expire_listener(&block : String ->)
      @cache.on_event do |event|
        if event.event_type == LRUCache::EventType::Exp
          block.call(event.key)
        end
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
        Log.info &.emit("setting 'notify-keyspace-events Ex' Redis config to inform about expired files")
        self.notify_keyspace_events_expiration
      end
      Log.info &.emit("files smaller than this size limit will be stored into the cache: '#{(@max_allowed_filesize * 1000).humanize_bytes}'")
    end

    private def notify_keyspace_events_expiration
      command = {"CONFIG", "SET", "notify-keyspace-events", "Ex"}
      @client.run(command)
    end

    def set(filename : String, filedata : String, expire_time : UInt64?)
      begin
        @client.set(filename, filedata, ex: expire_time)
      rescue ex
        Log.error &.emit("failed to insert file '#{filename}' from cache", error: ex.message)
        return
      end
    end

    def del(filename : String) : Nil
      @client.del(filename)
    end

    def get(filename : String) : Bytes?
      begin
        cached = @client.get(filename)
      rescue ex
        Log.error &.emit("failed to retrieve file '#{filename}' from cache", error: ex.message)
        return
      end
      if cached
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

    def expire_listener(&block : String ->)
      @client.subscribe "__keyevent@0__:expired" do |subscription, connection|
        subscription.on_message do |channel, message|
          # message is the filename that expired
          block.call(message)
        end
      end
    end
  end

  def init
    return if !CONFIG.cache.enabled

    case CONFIG.cache.type
    when Type::LRU
      @@cache = LRU.new
    when Type::Redis
      @@cache = RedisCache.new
    else
      @@cache = LRU.new
    end

    self.expire_listener
  end

  # NOTE: Since I have future ideas for Patchy being more distributed without a
  # central database. this may need to be deleted in the future because the
  # variable @@files is only for this Patchy process, which means that the
  # cached files information (name and filesize) will differ from instance
  # to instance. I guess that's fine.

  # This event listener will listen to expire events to delete expired files
  # from the @@files Hash.
  private def expire_listener
    cache = @@cache
    return if cache.nil?

    Log.debug &.emit("Listening to expire events")
    spawn(name: {{ @type.name.stringify }}) do
      if cache.is_a?(LRU)
        cache.expire_listener do |key|
          @@files.delete(key)
        end
      elsif cache.is_a?(RedisCache)
        cache.expire_listener do |key|
          @@files.delete(key)
        end
      end
    end
  end

  private def is_too_big_for_cache?(filename : String, filesize : Int64, max_allowed_filesize : Int32)
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

    filename = fileinfo.filename
    file = File.open(file_path)
    filesize = file.size

    return if is_too_big_for_cache?(filename, filesize, CONFIG.cache.max_allowed_filesize)

    if cache.is_a?(LRU)
      filedata = Bytes.new(filesize)
      file.read_fully(filedata)
      cache.set(filename, filedata, expire_time)
    elsif cache.is_a?(RedisCache)
      filedata = file.gets_to_end
      cache.set(filename, filedata, expire_time)
    else
      return
    end

    @@files[filename] = filesize

    file.close
    Log.trace &.emit("inserted file '#{filename}' to cache")
  end

  def delete(fileinfo : Fileinfo) : Nil
    cache = @@cache
    return if cache.nil?

    filename = fileinfo.filename
    cache.del(filename)

    @@files.delete(filename)

    Log.trace &.emit("deleted file '#{filename}' from cache")
  end

  def select(fileinfo : Fileinfo) : Bytes?
    cache = @@cache
    return if cache.nil?

    filename = fileinfo.filename
    hit = cache.get(filename)

    if hit
      Log.trace &.emit("retrieved file '#{filename}' from cache")
      hit
    else
      return
    end
  end

  def files
    return @@files
  end
end
