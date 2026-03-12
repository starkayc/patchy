class Kemal::ExceptionHandler
  private def call_exception_with_status_code(context : HTTP::Server::Context, exception : Exception, status_code : Int32)
    return if context.response.closed?

    if !Kemal.config.error_handlers.empty? && Kemal.config.error_handlers.has_key?(status_code)
      context.response.content_type = "text/html" unless context.response.headers.has_key?("Content-Type")
      context.response.status_code = status_code
      context.response.print Kemal.config.error_handlers[status_code].call(context, exception)
      context
    end
  end
end
