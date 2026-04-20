# Template — /project-init replaces FROM with the correct base image.
# Do not use this file directly until /project-init has run.
FROM python:3.12-slim

WORKDIR /workspace

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl && rm -rf /var/lib/apt/lists/*

COPY . .
