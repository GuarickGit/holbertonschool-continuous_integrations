FROM node:20-alpine

WORKDIR /usr/src/app

RUN addgroup app && adduser -S -G app app \
	&& chown app:app /usr/src/app

USER app

COPY --chown=app:app package*.json ./
RUN npm install
COPY --chown=app:app . .

# npm is only needed to install dependencies: remove it from the final image
USER root
RUN rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx
USER app

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
	CMD wget -qO- http://127.0.0.1:3000/health || exit 1

CMD ["node", "server.js"]
