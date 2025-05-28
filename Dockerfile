# Based on https://github.com/iv-org/invidious/blob/master/docker/Dockerfile
FROM crystallang/crystal:1.16.3-alpine AS builder

RUN apk add --no-cache sqlite-static yaml-static git

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

RUN --mount=type=cache,target=/root/.cache/crystal \
	crystal build ./src/patchy.cr \
	-O3 -Drelease \
	--static --warnings all -s -p -t

# 2nd stage
FROM alpine:3.21
# shared-mime-info is required so Crystal is able to guess the mime types
# of uploaded/retrieved files using the file `/etc/mime.types` provided
# by that package.
# This is subject to change with
# https://github.com/crystal-lang/crystal/issues/15763
RUN apk add --no-cache tini ffmpeg mailcap

WORKDIR /patchy

# Default environment variables for the container
ENV UPLOADER_THUMBNAILS=/data/files
ENV UPLOADER_THUMBNAILS=/data/thumbnails
ENV UPLOADER_DB=/data/db/db.sqlite3

RUN addgroup -g 10000 -S patchy && \
	adduser -u 10000 -S patchy -G patchy

RUN mkdir -p /data && chown -R 10000:10000 /data

COPY --from=builder /patchy/patchy /patchy
COPY --from=builder /patchy/public ./public

RUN chmod o+rX -R /patchy/patchy

RUN chown patchy: -R /patchy

EXPOSE 8080

USER patchy

ENTRYPOINT ["/sbin/tini", "--"]

CMD [ "/patchy/patchy" ]
