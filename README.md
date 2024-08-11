# file-uploader

Simple file uploader made on Crystal.
~~I'm making this to replace my current File uploader hosted on https://ayaya.beauty which uses https://github.com/nokonoko/uguu~~
Already replaced lol.

## Features

- Temporary file uploads like Uguu
- File deletion link (not available in frontend for now)
- Chatterino and ShareX support
- Video Thumbnails for Chatterino and FrankerFaceZ (Requires `ffmpeg` to be installed, can be disabled.)
- [Small Admin API](./src/handling/admin.cr) that allows you to delete files. (Needs to be enabled in the configuration)
- Unix socket support if you don't want to deal with all the TCP overhead
- Automatic protocol detection (HTTPS or HTTP)
- Low memory usage: Between 6MB at idle and 25MB if a file is being uploaded or retrieved. It will depend of your traffic.

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
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
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

## TODO

- ~~Add file size limit~~ ADDED
- ~~Fix error when accessing `http://127.0.0.1:8080` with an empty DB.~~ Fixed somehow.
- Better frontend...
- ~~Disable file deletion if `deleteFilesCheck` or `deleteFilesAfter` is set to `0`~~ DONE
- ~~Disable delete key if `deleteKeyLength` is `0`~~ DONE (But I think there is a better way to do it)
- ~~Exit if `fileameLength` is `0`~~ DONE
- ~~Disable file limit if `size_limit` is `0`~~ DONE
- ~~Prevent files from being overwritten in the event of a name collision~~ DONE
- Dockerfile and Docker image (Crystal doesn't has dependency hell like other languages so is not really necessary to do, but useful for people that want instant deploy)
- Custom file expiration using headers (Like rustypaste)
- Small CLI to upload files (like `rpaste` from rustypaste)
