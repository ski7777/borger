FROM docker:latest AS base
RUN apk add --no-cache borgbackup openssh-client

FROM base as base-jq
RUN apk add --no-cache jq

FROM base-jq as borger
ENV BORGER_LABEL_NAMESPACE="de.ski7777.borger"
COPY borger.sh /borger.sh
CMD ["/borger.sh"]

FROM base-jq as volumes
COPY volumes.sh /volumes.sh
CMD ["/volumes.sh"]