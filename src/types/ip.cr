struct IPInfo
  # Without this, this class will not be able to be used as `as: IP` on
  # SQL queries
  include DB::Serializable

  property ip : String
  property count : Int32
  property date : Int64

  def initialize(
    @ip = "",
    @count = 1,
    @date = 0,
  )
  end

  def to_tuple : Tuple(String, Int32, Int64)
    {% begin %}
      {
<<<<<<< HEAD
        {{@type.instance_vars.map(&.name).splat}}
=======
        {{ @type.instance_vars.map(&.name).splat }}
>>>>>>> upstream/master
      }
    {% end %}
  end
end
