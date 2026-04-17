FROM docker:latest AS base
RUN apk add --no-cache borgbackup openssh-client

FROM base as borger
ENV BORGER_LABEL_NAMESPACE="de.ski7777.borger"
COPY borger.sh /borger.sh
CMD ["/borger.sh"]

FROM base as volumes
RUN apk add --no-cache jq
COPY volumes.sh /volumes.sh
CMD ["/volumes.sh"]