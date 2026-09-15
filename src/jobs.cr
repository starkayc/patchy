require "./baked_fs"

# Pretty cool way to write background jobs! :)
module Jobs
  extend self
  Log = ::Log.for(self)

  def check_old_files : Fiber?
<<<<<<< HEAD
    if CONFIG.delete_files_check <= 0
=======
    if CONFIG.uploads.deletion.delete_files_check <= 0
>>>>>>> upstream/master
      Log.info &.emit("file deletion is disabled")
      return
    end
    spawn do
      loop do
        Utils.check_old_files
<<<<<<< HEAD
        sleep CONFIG.delete_files_check.seconds
=======
        sleep CONFIG.uploads.deletion.delete_files_check.seconds
>>>>>>> upstream/master
      end
    end
  end

  def retrieve_tor_exit_nodes : Fiber?
    return if !CONFIG.ip_block.tor.enabled

    Log.info &.emit("blocking Tor exit nodes")
    spawn do
      loop do
        Utils::IpBlocks::Tor.update_tor_exit_nodes
        sleep CONFIG.ip_block.tor.update_interval.seconds
      end
    end
  end

  def retrieve_vpn_addresses : Fiber?
    return if !CONFIG.ip_block.vpn.enabled

    Log.info &.emit("blocking VPN addresses")
    spawn do
      loop do
        Utils::IpBlocks::VPN.update_vpn_blocks
        sleep CONFIG.ip_block.vpn.update_interval.seconds
      end
    end
  end

<<<<<<< HEAD
  def kemal : Fiber
    Kemal.config.add_handler BakedFileHandler::BakedFileHandler.new(PublicAssets)
    if CONFIG.cors.enabled
      Kemal.config.add_handler Handlers::Options::CORSHeaders.new
    end
    spawn do
      if !CONFIG.server.unix_socket.nil?
        Utils.delete_socket
        Kemal.run &.server.not_nil!.bind_unix "#{CONFIG.server.unix_socket}"
        Log.info &.emit("changing socket permissions to 777")
        begin
          File.chmod("#{CONFIG.server.unix_socket}", File::Permissions::All)
        rescue ex
          Log.fatal &.emit("failed to set unix socket permissions to 777", error: ex.message)
          exit(1)
        end
      else
        begin
          Kemal.run(args: nil)
        rescue ex
          Log.fatal &.emit("patchy http server failed to start, exiting!", error: ex.message)
          exit(1)
=======
  def kemal : Fiber?
    Kemal.config.add_handler BakedFileHandler::BakedFileHandler.new(BakedFiles::PublicAssets)
    if CONFIG.cors.enabled
      Kemal.config.add_handler Handlers::Options::CORSHeaders.new
    end

    spawn do
      begin
        Kemal.run(args: nil) do |kemal_config|
          if !CONFIG.server.unix_socket.nil?
            Utils.delete_socket
            kemal_config.server.not_nil!.bind_unix "#{CONFIG.server.unix_socket}"
          end
        end
      rescue ex
        Log.fatal &.emit("patchy http server failed to start, exiting!", error: ex.message)
        exit(1)
      end
    end

    if !CONFIG.server.unix_socket.nil?
      loop do
        sleep 1.seconds
        if Kemal.config.running
          Log.info &.emit("changing socket permissions to 777")
          begin
            File.chmod("#{CONFIG.server.unix_socket}", File::Permissions::All)
            break
          rescue ex
            Log.fatal &.emit("failed to set unix socket permissions to 777", error: ex.message)
            exit(1)
          end
>>>>>>> upstream/master
        end
      end
    end
  end

<<<<<<< HEAD
  def gc : Fiber
    spawn do
      loop do
        GC.collect
        sleep 10.seconds
=======
  def gc : Fiber?
    if !CONFIG.advanced.gc.enabled
      Log.trace &.emit("gc enabled")
    end
    interval = CONFIG.advanced.gc.interval
    Log.trace &.emit("gc enabled", gc_call_interval: interval)

    spawn do
      loop do
        GC.collect
        sleep interval.seconds
>>>>>>> upstream/master
      end
    end
  end

<<<<<<< HEAD
  def run : Fiber
=======
  def run : Nil
>>>>>>> upstream/master
    check_old_files
    retrieve_tor_exit_nodes
    retrieve_vpn_addresses
    kemal
    gc
  end
end
