FROM docker.io/riscv64/alpine:edge

RUN apk add --no-cache nodejs npm tini

# toolchain solo per la build, poi via
RUN apk add --no-cache --virtual .build-deps \
        python3 make g++ linux-headers git \
 && npm install -g --unsafe-perm --omit=optional \
        --build-from-source=false node-red \
 && npm cache clean --force \
 && apk del .build-deps

ENV NODE_OPTIONS="--max-old-space-size=128 --max-semi-space-size=2 --v8-pool-size=0"
ENV NODE_RED_HOME=/data FLOWS=flows.json

WORKDIR /data

EXPOSE 1880

ENTRYPOINT ["/sbin/tini","--","node-red","--userDir","/data"]
