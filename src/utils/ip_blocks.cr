module Utils::IpBlocks
  module Tor
    extend self
    @@exit_nodes : Array(String) = [] of String

    def update_tor_exit_nodes : Nil
      Log.debug &.emit "update_tor_exit_nodes: Updating Tor exit nodes list"
      ips = [] of String

      url = "https://check.torproject.org/exit-addresses"
      uri = URI.parse(url)
      client = HTTP::Client.new(uri)
      client.dns_timeout = 5.seconds
      client.connect_timeout = 5.seconds
      client.read_timeout = 5.seconds

      begin
        res = client.get(uri.request_target)
      rescue ex : Socket::ConnectError
        Log.error &.emit "update_tor_exit_nodes: Failed to connect to #{url}: #{ex.message}"
        return
      rescue ex : IO::TimeoutError
        Log.error &.emit "update_tor_exit_nodes: Timeout trying to pull nodes: #{ex.message}"
        return
      rescue ex
        Log.error &.emit "update_tor_exit_nodes: Unknown error: #{ex.message}"
        return
      end

      if res.status_code == 200
        res.body.each_line do |line|
          if line.includes?("ExitAddress")
            ips << line.split(" ")[1]
          end
        end
        @@exit_nodes = ips
        Log.debug &.emit "update_tor_exit_nodes: Update done, IPs inside the Tor exit nodes list: #{@@exit_nodes.size}"
      else
        Log.error &.emit "update_tor_exit_nodes: Failed to retrieve exit nodes list. Status Code from '#{url}': #{res.status_code}"
        return
      end
    end

    def exit_nodes : Array(String)
      return @@exit_nodes
    end
  end

  module VPN
    extend self
    @@ips : Array(String) = [] of String

    enum Providers
      Mullvad
      IVPN
      AirVPN
    end

    struct MullvadResponse
      include JSON::Serializable

      getter ipv4_addr_in : String
    end

    struct AirVPNResponse
      include JSON::Serializable

      struct ServerInfo
        include JSON::Serializable

        getter ip_v4_in1 : String
        getter ip_v4_in2 : String
        getter ip_v4_in3 : String
        getter ip_v4_in4 : String
      end

      getter servers : Array(ServerInfo) = [] of ServerInfo
    end

    private def request_vpn_api(url : String) : HTTP::Client::Response?
      uri = URI.parse(url)
      client = HTTP::Client.new(uri)
      client.dns_timeout = 5.seconds
      client.connect_timeout = 5.seconds
      client.read_timeout = 5.seconds

      begin
        res = client.get(uri.request_target)
        if res.status_code == 200
          return res
        else
          Log.error &.emit "update_vpn_blocks: Request to '#{url}' returned a non 200 status code, skipping"
          return
        end
      rescue ex : Socket::ConnectError
        Log.error &.emit "update_vpn_blocks: Failed to connect to '#{url}': #{ex.message}"
        return
      rescue ex : IO::TimeoutError
        Log.error &.emit "update_vpn_blocks: Timeout trying to pull VPN data from '#{url}': #{ex.message}"
        return
      rescue ex
        Log.error &.emit "update_vpn_blocks: Unknown error: #{ex.message}"
        return
      end
    end

    def update_vpn_blocks : Nil
      Log.debug &.emit "update_vpn_blocks: Updating VPN addresses"
      ips = [] of String

      CONFIG.ip_block.vpn.providers.each do |provider|
        case provider
        when Providers::Mullvad
          Log.debug &.emit "update_vpn_blocks: Updating Mullvad addresses"
          data = request_vpn_api("https://api.mullvad.net/www/relays/all")
          if data
            data = Array(MullvadResponse).from_json(data.body)
            data.each do |item|
              ips << item.ipv4_addr_in
            end
          end
        when Providers::AirVPN
          Log.debug &.emit "update_vpn_blocks: Updating AirVPN addresses"
          data = request_vpn_api("https://airvpn.org/api/status/")
          if data
            data = AirVPNResponse.from_json(data.body)
            data.servers.each do |item|
              ips << item.ip_v4_in1
              ips << item.ip_v4_in2
              ips << item.ip_v4_in3
              ips << item.ip_v4_in4
            end
          end
        end
      end

      @@ips = ips
      Log.debug &.emit "update_vpn_blocks: Update done, IPs inside the VPN addresses list: #{@@ips.size}"
    end

    def ips : Array(String)
      return @@ips
    end
  end
end
