FROM node:22-bookworm

# End-to-end tests (Cypress) run outside the image, so its postinstall binary download is skipped.
ENV CYPRESS_INSTALL_BINARY=0

WORKDIR /app

COPY web/package*.json ./

RUN npm ci

COPY web/ .

EXPOSE 4200

CMD ["npm", "start"]
