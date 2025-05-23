# file-uploader

> [!WARNING]
> Project being rewritten, some features like the admin API and some upload endpoints are unavailable on 0.9.5

Simple file uploader made on Crystal.
~~I'm making this to replace my current File uploader hosted on https://ayaya.beauty which uses https://github.com/nokonoko/uguu~~

Already replaced lol.

## Features

- Temporary file uploads like Uguu
- File deletion link (not available in frontend for now)
- Chatterino and ShareX support
- Thumbnails for Chatterino and FrankerFaceZ (Requires `ffmpeg` to be installed, disabled by default)
- Rate Limiting
- [Small Admin API](./src/routes/admin/) that allows you to delete files, reset rate limits and more (Needs to be enabled in the configuration)
- Unix socket support if you don't want to deal with all the TCP overhead
- Automatic protocol detection (HTTPS or HTTP)
- Low memory usage: Between 6MB at idle and 25MB if a file is being uploaded or retrieved. It will depend of your traffic.
- Cache files on memory to reduce stress on the drive using [LRU](https://en.wikipedia.org/wiki/Cache_replacement_policies#LRU), more information on [config.example.yml](./config/config.example.yml)

## Usage

- Clone this repository, compile it using `shards build --release` and execute the server using `./bin/file-uploader`.
- Change the settings file `./config/config.yml` acording to what you need.

## NGINX Server block

Assuming you are already using NGINX and you know how to use it, you can use this example server block.

```
server {
    # You can keep the domain prefixed with `~.` if you want
    # to allow users to use any domain to upload and retrieve
    # files. Like xdxd.example.com or lolol.example.com .
    # This will only work if you have a wildcard domain.
	server_name ~.example.com example.com;

	location / {
        proxy_pass http://127.0.0.1:8080;
        # This if you want to use a UNIX socket instead
		#proxy_pass http://unix:/tmp/file-uploader.sock;
        proxy_set_header X-Real-IP   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host  $host;
		proxy_pass_request_headers      on;
	}

    # This should be the size_limit value (from config.yml)
	client_max_body_size 512M;

	listen 443 ssl;
	http2 on;
}
```
## Systemd user service example

```
[Unit]
Description=file-uploader-crystal
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=2
LimitNOFILE=4096
Environment="KEMAL_ENV=production"
ExecStart=%h/file-uploader-crystal/bin/file-uploader
WorkingDirectory=%h/file-uploader-crystal/

[Install]
WantedBy=default.target
```
