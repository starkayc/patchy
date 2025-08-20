require "benchmark"

module Routes::Admin
  extend self

  struct VpnResponse
    include JSON::Serializable

    property ips : Array(String) = Utils::IpBlocks::VPN.ips

    def initialize
    end
  end

  # /-/api/admin/vpns
  # curl -X GET -H "X-Api-Key: asd" http://localhost:8080/-/api/admin/vpns | jq
  def vpn_ips(env : HTTP::Server::Context) : String
    VpnResponse.new.to_json
  end
end
