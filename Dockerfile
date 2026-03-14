# Based on https://github.com/iv-org/invidious/blob/master/docker/Dockerfile
FROM crystallang/crystal:1.19.1-alpine AS builder

RUN apk add --no-cache sqlite-static yaml-static

WORKDIR /patchy

COPY ./shard.yml ./shard.yml
COPY ./shard.lock ./shard.lock
RUN shards install --production

COPY ./src/ ./src/
# TODO: .git folder is required for building – this is destructive.
# See definition of CURRENT_BRANCH, CURRENT_COMMIT and CURRENT_VERSION.
COPY ./.git/ ./.git/

# Copy public folder to image
COPY ./public/ ./public/
COPY ./locales/ ./locales/

<<<<<<< HEAD
# Passed from CI so the Crystal compile-time macro gets the real branch name
# even when the checkout is in detached HEAD state (e.g. GitHub Actions).
ARG CURRENT_BRANCH
ENV CURRENT_BRANCH=${CURRENT_BRANCH}

=======
>>>>>>> upstream/master
RUN --mount=type=cache,target=/root/.cache/crystal \
	crystal build ./src/patchy.cr \
	--release \
	--static --warnings all -s -p -t

<<<<<<< HEAD
FROM alpine:3.23
=======
FROM git.nadeko.net/fijxu/alpine-stripped-ffmpeg:3.23-ffmpeg-6.1.2
>>>>>>> upstream/master
# shared-mime-info is required so Crystal is able to guess the mime types
# of uploaded/retrieved files using the file `/etc/mime.types` provided
# by that package.
# This is subject to change with
# https://github.com/crystal-lang/crystal/issues/15763
RUN apk add --no-cache \
	tini \
	mailcap \
<<<<<<< HEAD
	ffmpeg \
=======
>>>>>>> upstream/master
	libvpx \
	x264-libs \
	x265-libs \
	aom-libs \
	libwebp \
	libwebpmux \
	libjxl \
	libpng \
<<<<<<< HEAD
	libjpeg-turbo
=======
	libjpeg
>>>>>>> upstream/master

RUN rm -rf /var/cache/apk/* /tmp/*

WORKDIR /patchy

# Default environment variables for the container
ENV UPLOADER_FILES=/data/files
ENV UPLOADER_THUMBNAILS=/data/thumbnails
ENV UPLOADER_DB=/data/db/db.sqlite3

RUN adduser -u 10000 -S patchy

RUN mkdir -p /data && chown -R 10000:10000 /data

COPY --from=builder --chown=patchy:patchy /patchy/patchy /patchy

EXPOSE 8080

USER patchy

ENTRYPOINT ["/sbin/tini", "--"]

CMD [ "/patchy/patchy" ]
