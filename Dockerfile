FROM docker:latest AS base
RUN apk add --no-cache jq borgbackup openssh-client

FROM base as volumes
COPY volumes.sh /volumes.sh
CMD ["/volumes.sh"]