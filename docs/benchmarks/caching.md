Patchy has a file cache that stores files that weigth less than
`cache.max_allowed_filesize` (from
[config.example.yml](../../config/config.example.yml)) into RAM, this is really
useful if your server has a very high load on specific files saved into the
cache.

To test how effective the cache is, I did some benchmarks using `wrk`, tracking
how many [openat](https://www.man7.org/linux/man-pages/man3/open.3p.html)
syscalls patchy did using `sudo strace -e trace=open,openat -p $(pidof patchy)`
and with this cache configuration:

```yaml
cache:
    enabled: true
    max_size: 256
    max_allowed_filesize: 512
```

I also compiled patchy using `Kemal.config.logging = false` on `patchy.cr` to
disable any sort of logging

## Testing

I uploaded a 468KiB file and I started the test against the file uploaded, and I
got:

### With cache

```
$ wrk -c 100 http://localhost:10006/-/file/A63
Running 10s test @ http://localhost:10006/-/file/A63
  2 threads and 100 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    56.83ms   35.34ms 231.83ms   72.94%
    Req/Sec     0.93k   265.79     1.28k    74.37%
  18470 requests in 10.02s, 8.25GB read
Requests/sec:   1843.40
Transfer/sec:    843.64MB
```

```
$ sudo strace -e trace=open,openat -p $(pidof patchy)
strace: Process 24260 attached
openat(AT_FDCWD, "./data/files/A63.png", O_RDONLY|O_CLOEXEC) = 12
openat(AT_FDCWD, "/etc/mime.types", O_RDONLY|O_CLOEXEC) = 12
openat(AT_FDCWD, "/etc/httpd/conf/mime.types", O_RDONLY|O_CLOEXEC) = 12
openat(AT_FDCWD, "/home/user/git/patchy/data/files/A63.png", O_RDONLY|O_CLOEXEC) = 12
--- SIGPIPE {si_signo=SIGPIPE, si_code=SI_USER, si_pid=24260, si_uid=1000} ---
--- SIGPIPE {si_signo=SIGPIPE, si_code=SI_USER, si_pid=24260, si_uid=1000} ---
```

**1843req/s** with only one syscall
(`openat(AT_FDCWD, "/home/user/git/patchy/data/files/A63.png", O_RDONLY|O_CLOEXEC) = 12`)
to the file being retrieved. Pretty ok.
(`--- SIGPIPE {si_signo=SIGPIPE, si_code=SI_USER, si_pid=24260, si_uid=1000} ---`
messages appear when `wrk` finishes the benchmark since it breaks the HTTP
connection, so that's nothing to worry about)

### Without cache

```
$ wrk -c 100 http://localhost:10006/-/file/A63
Running 10s test @ http://localhost:10006/-/file/A63
  2 threads and 100 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   137.74ms   17.79ms 280.72ms   92.14%
    Req/Sec   362.05     57.51   505.00     82.00%
  7213 requests in 10.01s, 3.24GB read
Requests/sec:    720.59
Transfer/sec:    331.09MB
```

```
$ sudo strace -e trace=open,openat -p $(pidof patchy)
strace: Process 24978 attached
openat(AT_FDCWD, "/etc/mime.types", O_RDONLY|O_CLOEXEC) = 12
openat(AT_FDCWD, "/etc/httpd/conf/mime.types", O_RDONLY|O_CLOEXEC) = 12
openat(AT_FDCWD, "/home/user/git/patchy/data/files/A63.png", O_RDONLY|O_CLOEXEC) = 12
openat(AT_FDCWD, "/home/user/git/patchy/data/files/A63.png", O_RDONLY|O_CLOEXEC) = 12
openat(AT_FDCWD, "/home/user/git/patchy/data/files/A63.png", O_RDONLY|O_CLOEXEC) = 12
openat(AT_FDCWD, "/home/user/git/patchy/data/files/A63.png", O_RDONLY|O_CLOEXEC) = 12
openat(AT_FDCWD, "/home/user/git/patchy/data/files/A63.png", O_RDONLY|O_CLOEXEC) = 12
openat(AT_FDCWD, "/home/user/git/patchy/data/files/A63.png", O_RDONLY|O_CLOEXEC) = 12
openat(AT_FDCWD, "/home/user/git/patchy/data/files/A63.png", O_RDONLY|O_CLOEXEC) = 12
openat(AT_FDCWD, "/home/user/git/patchy/data/files/A63.png", O_RDONLY|O_CLOEXEC) = 12
openat(AT_FDCWD, "/home/user/git/patchy/data/files/A63.png", O_RDONLY|O_CLOEXEC) = 12
...
```

Only **720req/s** and the system being spammed with `openat` syscalls, -60,93%
less performant than using cache.

#### Note

This was tested using the `balanced` CPU governor on an Intel i5-7400 and using
an SSD to store the files!

## So, should I enable caching on Patchy?

If you have plenty of RAM to waste or you think there is a lot of people that
are going to gather a single file in a short time, then enable cache, it will
keep your disk usage low for files that are being gathered a lot of times.
