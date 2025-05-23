# Pretty cool way to write background jobs! :)
module Jobs
  extend self

  def check_old_files
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

  def retrieve_tor_exit_nodes
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

  def kemal
    spawn do
      if !CONFIG.unix_socket.nil?
        Utils.delete_socket
        Kemal.run &.server.not_nil!.bind_unix "#{CONFIG.unix_socket}"
        LOGGER.info "Changing socket permissions to 777"
        begin
          File.chmod("#{CONFIG.unix_socket}", File::Permissions::All)
        rescue ex
          LOGGER.fatal "Failed to set unix socket permissions to 777: #{ex.message}"
          exit(1)
        end
      else
        Kemal.run
      end
    end
  end

  def run
    check_old_files
    retrieve_tor_exit_nodes
    kemal
  end
end
