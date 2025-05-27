module Utils::Tor
  extend self
  @@exit_nodes : Array(String) = [] of String

  def update_tor_exit_nodes
    LOGGER.debug "update_tor_exit_nodes: Updating Tor exit nodes list"
    ips = [] of String

    uri = URI.parse(CONFIG.tor_exit_nodes_url)
    client = HTTP::Client.new(uri)
    client.dns_timeout = 5.seconds
    client.connect_timeout = 5.seconds
    client.read_timeout = 5.seconds

    begin
      res = client.get(uri.request_target)
    rescue ex : Socket::ConnectError
      LOGGER.error "update_tor_exit_nodes: Failed to connect to #{CONFIG.tor_exit_nodes_url}: #{ex.message}"
      return
    rescue ex : IO::TimeoutError
      LOGGER.error "update_tor_exit_nodes: Timeout trying to pull nodes: #{ex.message}"
      return
    rescue ex
      LOGGER.error "update_tor_exit_nodes: Unknown error: #{ex.message}"
      return
    end

    if res.success? && res.status_code == 200
      res.body.each_line do |line|
        if line.includes?("ExitAddress")
          ips << line.split(" ")[1]
        end
      end
      @@exit_nodes = ips
      LOGGER.debug "update_tor_exit_nodes: Update done, IPs inside the Tor exit nodes list: #{@@exit_nodes.size}"
    else
      LOGGER.error "update_tor_exit_nodes: Failed to retrieve exit nodes list. Status Code from '#{CONFIG.tor_exit_nodes_url}': #{res.status_code}"
      return
    end
  end

  def exit_nodes : Array(String)
    return @@exit_nodes
  end
end
