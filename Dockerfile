FROM docker:latest AS base
RUN apk add --no-cache jq borgbackup openssh-client