FROM docker:latest AS base
ARG revision
RUN apk add --no-cache borgbackup openssh-client
RUN mkdir -p /var/borger && echo "$revision" > /var/borger/revision

FROM base AS base-jq
RUN apk add --no-cache jq

FROM base-jq AS borger
ENV BORGER_LABEL_NAMESPACE="de.ski7777.borger"
COPY borger.sh /borger.sh
CMD ["/borger.sh"]

FROM base-jq AS volumes
COPY volumes.sh /volumes.sh
CMD ["/volumes.sh"]
