struct UFile
  # Without this, this class will not be able to be used as `as: UFile` on
  # SQL queries
  include DB::Serializable

  property original_filename : String
  property filename : String
  property extension : String
  property uploaded_at : Int64
  property checksum : String?
  property ip : String
  property delete_key : String
  property thumbnail : String?

  def initialize(
    @original_filename = "",
    @filename = "",
    @extension = "",
    @uploaded_at = 0,
    @checksum = nil,
    @ip = "",
    @delete_key = "",
    @thumbnail = nil,
  )
  end

  def to_tuple
    {% begin %}
      {
        {{@type.instance_vars.map(&.name).splat}}
      }
    {% end %}
  end
end
