require "benchmark"

module Routes::Admin
  extend self

  struct TorResponse
    include JSON::Serializable

    property ips : Array(String) = Utils::Tor.exit_nodes

    def initialize
    end
  end

  # /api/admin/torexitnodes
  # curl -X GET -H "X-Api-Key: asd" http://localhost:8080/api/admin/torexitnodes | jq
  def tor_exit_nodes(env)
    TorResponse.new.to_json
  end
end
