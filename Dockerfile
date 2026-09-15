# syntax=docker/dockerfile:1

# Container image bundling the GitHub codeql-action wrapper code and the matching
# CodeQL CLI bundle. The image tag follows the codeql-action package version,
# while the bundled CodeQL CLI version is pinned to the value declared in
# src/defaults.json (currently 2.27.0).

FROM node:20-slim

ARG CODEQL_ACTION_VERSION=4.38.0
ARG CODEQL_CLI_VERSION=2.27.0
ARG CODEQL_BUNDLE_TAG=codeql-bundle-v2.27.0

LABEL org.opencontainers.image.title="codeql-action" \
      org.opencontainers.image.version="${CODEQL_ACTION_VERSION}" \
      codeql-cli-version="${CODEQL_CLI_VERSION}"

WORKDIR /tmp

# Install tools required to download and extract the CodeQL bundle.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    && rm -rf /var/lib/apt/lists/*

# Download and install the CodeQL CLI bundle.
RUN curl -fsSL \
    "https://github.com/github/codeql-action/releases/download/${CODEQL_BUNDLE_TAG}/codeql-bundle-linux64.tar.gz" \
    -o codeql-bundle.tar.gz \
    && mkdir -p /usr/local/codeql \
    && tar -xzf codeql-bundle.tar.gz -C /usr/local/codeql \
    && rm codeql-bundle.tar.gz

ENV PATH="/usr/local/codeql/codeql:${PATH}"

# Copy the action source so the image remains self-contained and versioned.
WORKDIR /action
COPY . .

# The action is normally driven by GitHub Actions runtime; in Tekton we invoke
# CodeQL CLI commands directly. The entrypoint below just exposes the CLI.
ENTRYPOINT ["codeql"]
CMD ["--help"]
