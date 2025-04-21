module Utils::Tor
  extend self
  @@exit_nodes : Array(String) = [] of String

  def refresh_exit_nodes
    LOGGER.debug "reload_exit_nodes: Updating Tor exit nodes list"
    retrieve_tor_exit_nodes
    LOGGER.debug "reload_exit_nodes: IPs inside the Tor exit nodes list: #{@@exit_nodes.size}"
  end

  def retrieve_tor_exit_nodes
    LOGGER.debug "retrieve_tor_exit_nodes: Retrieving Tor exit nodes list"
    ips = [] of String

    HTTP::Client.get(CONFIG.torExitNodesUrl) do |res|
      begin
        if res.success? && res.status_code == 200
          res.body_io.each_line do |line|
            if line.includes?("ExitAddress")
              ips << line.split(" ")[1]
            end
          end
          @@exit_nodes = ips
        else
          LOGGER.error "retrieve_tor_exit_nodes: Failed to retrieve exit nodes list. Status Code: #{res.status_code}"
        end
      rescue ex : Socket::ConnectError
        LOGGER.error "retrieve_tor_exit_nodes: Failed to connect to #{CONFIG.torExitNodesUrl}: #{ex.message}"
      rescue ex
        LOGGER.error "retrieve_tor_exit_nodes: Unknown error: #{ex.message}"
      end
    end
  end

  def exit_nodes : Array(String)
    return @@exit_nodes
  end
end
