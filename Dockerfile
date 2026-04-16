FROM docker:latest AS base
RUN apk add --no-cache borgbackup openssh-client

FROM base as volumes
RUN apk add --no-cache jq
COPY volumes.sh /volumes.sh
CMD ["/volumes.sh"]