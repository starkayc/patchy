require "uri/params/serializable"

# Modified URI::Params::Serializable to include `after_initialize`
# Should be added to the stdlib:
# https://github.com/crystal-lang/crystal/pull/16874
module URI::Params::Serializable
  macro included
      def self.from_www_form(params : ::String)
        new_from_www_form ::URI::Params.parse params
      end

      # :nodoc:
      #
      # This is needed so that nested types can pass the name thru internally.
      # Has to be public so the generated code can call it, but should be considered an implementation detail.
      def self.from_www_form(params : ::URI::Params, name : ::String)
        new_from_www_form(params, name)
      end

      protected def self.new_from_www_form(params : ::URI::Params, name : ::String? = nil)
        instance = allocate
        instance.initialize(__uri_params: params, name: name)
        GC.add_finalizer(instance) if instance.responds_to?(:finalize)
        instance
      end

      macro inherited
        def self.from_www_form(params : ::String)
          new_from_www_form ::URI::Params.parse params
        end

        # :nodoc:
        def self.from_www_form(params : ::URI::Params, name : ::String)
          new_from_www_form(params, name)
        end
      end

      # :nodoc:
      def initialize(*, __uri_params params : ::URI::Params, name : String?)
        {% verbatim do %}
          {% begin %}
            {% for ivar, idx in @type.instance_vars %}
              %name{idx} = name.nil? ? {{ivar.name.stringify}} : "#{name}[#{{{ivar.name.stringify}}}]"
              %value{idx} = {{(ann = ivar.annotation(URI::Params::Field)) && (converter = ann["converter"]) ? converter : ivar.type}}.from_www_form params, %name{idx}

              unless %value{idx}.nil?
                @{{ivar.name.id}} = %value{idx}
              else
                {% unless ivar.type.resolve.nilable? || ivar.has_default_value? %}
                  raise URI::SerializableError.new "Missing required property: '#{%name{idx}}'."
                {% end %}
              end
            {% end %}
          {% end %}
        {% end %}
        after_initialize
      end
    end

  protected def after_initialize
  end

  def to_www_form(*, space_to_plus : Bool = true) : String
    URI::Params.build(space_to_plus: space_to_plus) do |form|
      {% for ivar in @type.instance_vars %}
          @{{ivar.name.id}}.to_www_form form, {{ivar.name.stringify}}
        {% end %}
    end
  end

  # :nodoc:
  def to_www_form(builder : URI::Params::Builder, name : String)
    {% for ivar in @type.instance_vars %}
        @{{ivar.name.id}}.to_www_form builder, "#{name}[#{{{ivar.name.stringify}}}]"
      {% end %}
  end
end

struct UserSettings
  include JSON::Serializable
  include URI::Params::Serializable

  property filename_length : Int32 = CONFIG.uploads.filename_length

  def after_initialize
    @filename_length = @filename_length.clamp(CONFIG.min_filename_length, CONFIG.max_filename_length)
  end
end
