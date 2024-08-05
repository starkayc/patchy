# file-uploader

Simple file uploader made on Crystal.
~~I'm making this to replace my current File uploader hosted on https://ayaya.beauty which uses https://github.com/nokonoko/uguu~~ Already replaced lol.

## Features

- Temporary file file uploader like Uguu
- File deletion link (not available in frontend for now)
- Chatterino and ShareX support
- Unix socket support if you don't want to deal with all the TCP overhead
- Low memory usage: Between 6MB at idle and 25MB if a file is being uploaded or retrieved. I will depend of your traffic.

## TODO

- ~~Add file size limit~~ ADDED
- Fix error when accessing `http://127.0.0.1:8080` with an empty DB.
- Better frontend...
- ~~Disable file deletion if `delete_files_after_check_seconds` or `delete_files_after` is set to `0`~~ DONE
- ~~Disable delete key if `delete_key_length` is `0`~~ DONE (But I think there is a better way to do it)
- ~~Exit if `filename_length` is `0`~~ DONE
- ~~Disable file limit if `size_limit` is `0`~~ DONE
- ~~Prevent files from being overwritten in the event of a name collision~~ DONE
- Dockerfile and Docker image (Crystal doesn't has dependency hell like other languages so is not really necessary to do, but useful for people that want instant deploy)
