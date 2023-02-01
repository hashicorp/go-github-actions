# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

FROM docker.mirror.hashicorp.services/python:3-alpine

LABEL "maintainer"="Kim Ngo <kngo@hashicorp.com>"
LABEL "repository"="https://github.com/hashicorp/go-github-actions"
LABEL "version"="0.1.0"

LABEL "com.github.actions.name"="vendor diff"
LABEL "com.github.actions.description"="Verify vendor is up to date with go mod"
LABEL "com.github.actions.icon"="check-circle"
LABEL "com.github.actions.color"="blue"

RUN apk --no-cache add bash curl jq

COPY vendor-diff.py entrypoint.sh /
ENTRYPOINT [ "/entrypoint.sh" ]
