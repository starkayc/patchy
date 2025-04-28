# Pretty cool way to write background jobs! :)
module Jobs
  def self.check_old_files
    if CONFIG.delete_files_check <= 0
      LOGGER.info "File deletion is disabled"
      return
    end
    spawn do
      loop do
        Utils.check_old_files
        sleep CONFIG.delete_files_check.seconds
      end
    end
  end

  def self.retrieve_tor_exit_nodes
    if !CONFIG.block_tor_addresses
      return
    end
    LOGGER.info("Blocking Tor exit nodes")
    spawn do
      loop do
        Utils::Tor.refresh_exit_nodes
        sleep CONFIG.tor_exit_nodes_check.seconds
      end
    end
  end

  def self.kemal
    spawn do
      if !CONFIG.unix_socket.nil?
        Kemal.run &.server.not_nil!.bind_unix "#{CONFIG.unix_socket}"
      else
        Kemal.run
      end
    end
  end

  def self.run
    check_old_files
    retrieve_tor_exit_nodes
    kemal
  end
end
