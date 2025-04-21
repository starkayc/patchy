struct IP
  # Without this, this class will not be able to be used as `as: UFile` on
  # SQL queries
  include DB::Serializable

  property ip : String
  property count : Int32
  property unix_date : Int32

  def initialize(
    @ip,
    @count,
    @unix_date,
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
