# file-uploader

Simple file uploader made on Crystal.
I'm making this to replace my current File uploader hosted on https://ayaya.beauty which uses https://github.com/nokonoko/uguu

## Features

- Temporary file file uploader like Uguu
- File deletion link (not available in frontend for now)
- Chatterino and ShareX support
- Low memory usage: Between 6MB at idle and 25MB if a file is being uploaded of retrieved. I will depend of your traffic.

## TODO

- ~~Add file size limit~~ ADDED
- Fix error when accessing `http://127.0.0.1:8080` with an empty DB.
- Better frontend...
- Disable file deletion if `delete_files_after_check_seconds` or `delete_files_after` is set to `0`
- Disable delete key if `delete_key_lenght` is `0`
- Exit if `filename_lenght` is `0`
- Disable file limit if `size_limit` is `0`
- 

