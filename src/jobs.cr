require "./baked_fs"

# Pretty cool way to write background jobs! :)
module Jobs
  extend self

  def check_old_files
    if CONFIG.delete_files_check <= 0
      Log.info &.emit "File deletion is disabled"
      return
    end
    spawn do
      loop do
        Utils.check_old_files
        sleep CONFIG.delete_files_check.seconds
      end
    end
  end

  def retrieve_tor_exit_nodes
    if !CONFIG.ip_block.tor.enabled
      return
    end
    Log.info &.emit "Blocking Tor exit nodes"
    spawn do
      loop do
        Utils::IpBlocks::Tor.update_tor_exit_nodes
        sleep CONFIG.ip_block.tor.update_interval.seconds
      end
    end
  end

  def retrieve_vpn_addresses
    if !CONFIG.ip_block.vpn.enabled
      return
    end
    Log.info &.emit "Blocking VPN addresses"
    spawn do
      loop do
        Utils::IpBlocks::VPN.update_vpn_blocks
        sleep CONFIG.ip_block.vpn.update_interval.seconds
      end
    end
  end

  def kemal
    add_handler BakedFileHandler::BakedFileHandler.new(PublicAssets)
    spawn do
      if !CONFIG.server.unix_socket.nil?
        Utils.delete_socket
        Kemal.run &.server.not_nil!.bind_unix "#{CONFIG.server.unix_socket}"
        Log.info &.emit "Changing socket permissions to 777"
        begin
          File.chmod("#{CONFIG.server.unix_socket}", File::Permissions::All)
        rescue ex
          Log.fatal &.emit "Failed to set unix socket permissions to 777: #{ex.message}"
          exit(1)
        end
      else
        Kemal.run
      end
    end
  end

  def gc
    spawn do
      loop do
        GC.collect
        sleep 10.seconds
      end
    end
  end

  def run
    check_old_files
    retrieve_tor_exit_nodes
    retrieve_vpn_addresses
    kemal
    gc
  end
end
