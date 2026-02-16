Patchy uses ffmpeg to generate thumbnails, but ffmpeg and formats have a lot of
features that could be exploited, because of that, the Patchy OCI uses a
self-compiled ffmpeg build to strip those unneeded functions that could be
exploited to do undesired behavior in the server where Patchy is running.

ffmpeg is built with this flags:

```
--enable-version3 \
--enable-gpl \
--enable-nonfree \
--enable-small \
--enable-libaom \
--enable-libx264 \
--enable-libx265 \
--enable-libvpx \
--enable-libwebp \
--enable-libjxl \
--disable-librtmp \
--disable-lzma \
--disable-debug \
--disable-doc \
--disable-ffplay \
--disable-ffprobe \
--disable-protocols \
--enable-protocol=file,pipe \
--disable-network \
```

(https://git.nadeko.net/Fijxu/crystal-oci-images/src/branch/master/Dockerfile-alpine-stripped-ffmpeg.dockerfile#L36)

It enables a minimal set of codecs to process thumbnails, it disables all
protocols and only enables `file,pipe` in order to allow ffmpeg process files
from arguments and piping.

It also disables all network related things to prevent ffmpeg from doing
requests to a remote host.

## Why, is it really necessary, how this could be abused?

ffmpeg doesn't care about the file extension that is being server, it will read
the file and assume it's codec or format based on their contents, this makes
attackers able to upload a `.png` but with other type of content unrelated to a
real `.png` file, it could be a text file and ffmpeg will threat it like a text
file.

For example, a `.png` could be a simple text file with **M3U** data on it, and
M3U has the ability to do remote access, therefore ffmpeg will fetch the URL
that is inside that fake `.png` file.

---

If you are going to host Patchy, please be aware of thumbnail generation as it
could lead to a third party exploiting your server
