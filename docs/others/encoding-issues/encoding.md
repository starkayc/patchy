# Solving encoding issues with some uploaded text files

Recently someone reported an issue with text files that contained Russian text.
They were displayed like weird characters in the browser, but when the file was
downloaded, the contents were readable.

The issue was that for some reason that I still don't know, browsers (Firefox based
and Chromium based) used the `Windows-1252` charset, which seems to be incompatible
with Russian characters and they just were unreadable in the browser.

So because of that I had to detect the charset of the file and add it to the
`Content-Type` header so the browser uses the charset that is detected by Patchy
when it sends the file to the client.

## Solution time lol

One of the most popular libraries that are used to detect the **type**, **charset**,
and other details about a file, is `libmagic` (https://www.man7.org/linux/man-pages/man3/libmagic.3.html)

It can detect the type of file based on the magic bytes of a file, instead of relying only
in their file extension. I always wanted to implement `libmagic` into Patchy, primarily to
detect files uploaded that used fake extensions, for example, someone could rename a `hehe.exe`
file to `hehe.png` file and bypass the blocked extensions list, or just upload files
with a wrong extension.

Now that libmagic is implemented, Patchy can detect files with faked extensions (not implemented for now)
and the charset of the files, which was needed to solve this issue.

So now, Pathcy will read the file, detect it's mime type and encoding so it can be used in the `Content-Type`
header to inform the browser of which charset to use when displaying certain characters in text files.

Thanks to https://github.com/athena-framework/mime/blob/f11a7f991a00b4f95a5e274bc05d10e686569570/src/magic_types_guesser.cr
since I took most of the `libmagic` implementation for Patchy from there. I could have used `athena-framework/mime`
as a dependency, but I needed to modify the library too much just to add encoding (charset) detection.
