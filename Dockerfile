FROM node:20.11-alpine3.18 as build

RUN npm install -g pnpm

# Move files into the image and install
WORKDIR /app
COPY ./service ./
RUN wget https://github.com/DistPub/atproto-pds/archive/refs/heads/main.zip && \
    unzip main.zip && rm main.zip && \
    cd atproto-pds-main && pnpm install && \
    pnpm run build && cd .. && pnpm add ./atproto-pds-main

# Uses assets from build stage to reduce build size
FROM node:20.11-alpine3.18

RUN apk add --update dumb-init

# Avoid zombie processes, handle signal forwarding
ENTRYPOINT ["dumb-init", "--"]

WORKDIR /app
COPY --from=build /app /app

EXPOSE 3000
ENV PDS_PORT=3000
ENV NODE_ENV=production
# potential perf issues w/ io_uring on this version of node
ENV UV_USE_IO_URING=0

CMD ["node", "--enable-source-maps", "index.js"]

LABEL org.opencontainers.image.source=https://github.com/bluesky-social/pds
LABEL org.opencontainers.image.description="AT Protocol PDS"
LABEL org.opencontainers.image.licenses=MIT
