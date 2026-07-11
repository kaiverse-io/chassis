FROM mcr.microsoft.com/devcontainers/python:1-3.12-bookworm

# See template/.devcontainer/Dockerfile.jinja for the full explanation — the base
# image bakes in a Yarn apt source whose signature no longer verifies against
# Yarn's current keyring (frozen since the image's 2025-07-10 publish, predates
# Yarn's 2026-01 key rotation). Dropping it here too since chassis's own devcontainer
# is just as exposed on a fresh clone as any stamped project.
RUN rm -f /etc/apt/sources.list.d/yarn.list
