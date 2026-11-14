# Hi, compile me with `crystal run encoding.cr` to
# test how the text file is displayed when using
# charset and not charset in the Content-Type header.

require "http/server"
require "mime"

file_path = "./russian-text.txt"
file = File.read(file_path)

server = HTTP::Server.new do |context|
  context.response.content_type = "text/plain"
  context.response.print file
end
address = server.bind_tcp 58080

server_ = HTTP::Server.new do |context|
  context.response.content_type = "text/plain; charset=utf-8"
  context.response.print file
end
address_ = server_.bind_tcp 58081

spawn do
  puts "Listening on http://#{address}"
  server.listen
end

spawn do
  puts "Listening on http://#{address_}"
  server_.listen
end

sleep
