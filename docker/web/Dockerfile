FROM node:22-bookworm

# End-to-end tests (Cypress) run outside the image, so its postinstall binary download is skipped.
ENV CYPRESS_INSTALL_BINARY=0

WORKDIR /app

# The official image ships an unprivileged "node" user; /app and the dev-server cache must belong to it
# before the switch. Compose mounts a volume on /app/.angular, which inherits this ownership.
RUN mkdir /app/.angular && chown node:node /app /app/.angular

COPY docker/web/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER node

COPY --chown=node:node web/package*.json ./

RUN npm ci

COPY --chown=node:node web/ .

EXPOSE 4200

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
