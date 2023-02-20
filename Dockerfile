FROM ubuntu:focal AS builder

ENV NODE_ENV="production"

RUN set -ex; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get -qq update; \
    apt-get -y --no-install-recommends install \
      build-essential \
      ca-certificates \
      wget \
      pkg-config \
      xvfb \
      libglfw3-dev \
      libuv1-dev \
      libjpeg-turbo8 \
      libicu66 \
      libcairo2-dev \
      libpango1.0-dev \
      libjpeg-dev \
      libgif-dev \
      librsvg2-dev \
      gir1.2-rsvg-2.0 \
      librsvg2-2 \
      librsvg2-common \
      libcurl4-openssl-dev \
      libpixman-1-dev \
      libpixman-1-0; \
      apt-get -y --purge autoremove; \
      apt-get clean; \
      rm -rf /var/lib/apt/lists/*;

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN wget -qO- https://deb.nodesource.com/setup_18.x | bash; \
    apt-get install -y nodejs; \
    npm i -g npm@latest; \
    apt-get -y remove wget; \
    apt-get -y --purge autoremove; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*;

RUN mkdir -p /usr/src/app

WORKDIR /usr/src/app

COPY package.json /usr/src/app
COPY package-lock.json /usr/src/app

RUN npm ci --omit=dev



FROM ubuntu:focal AS final

# Install system dependencies
RUN set -e; \
    apt-get update -y
RUN apt-get install -y \
    gnupg \
    curl \
    tini \
    lsb-release; \
    gcsFuseRepo=gcsfuse-`lsb_release -c -s`; \
    echo "deb http://packages.cloud.google.com/apt $gcsFuseRepo main" | \
    tee /etc/apt/sources.list.d/gcsfuse.list; \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    apt-key add -; \
    apt-get update; \
    apt-get install -y gcsfuse \
    && apt-get clean

# Set fallback mount directory
ENV MNT_DIR /data

ENV \
    NODE_ENV="production" \
    CHOKIDAR_USEPOLLING=1 \
    CHOKIDAR_INTERVAL=500

RUN set -ex; \
    export DEBIAN_FRONTEND=noninteractive; \
    groupadd -r node; \
    useradd -r -g node node; \
    apt-get -qq update; \
    apt-get -y --no-install-recommends install \
      ca-certificates \
      wget \
      xvfb \
      libglfw3 \
      libuv1 \
      libjpeg-turbo8 \
      libicu66 \
      libcairo2 \
      libgif7 \
      libopengl0 \
      libpixman-1-0 \
      libcurl4 \
      librsvg2-2 \
      libpango-1.0-0; \
      apt-get -y --purge autoremove; \
      apt-get clean; \
      rm -rf /var/lib/apt/lists/*;

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN wget -qO- https://deb.nodesource.com/setup_18.x | bash; \ 
    apt-get install -y nodejs; \
    npm i -g npm@latest; \
    apt-get -y remove wget; \
    apt-get -y --purge autoremove; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*;

COPY --from=builder /usr/src/app /usr/src/app

COPY . /usr/src/app

RUN mkdir -p /data && chown node:node /data
# VOLUME /data
WORKDIR /data

EXPOSE 8080

USER node:node

ENTRYPOINT ["/usr/src/app/docker-entrypoint.sh"]

HEALTHCHECK CMD node /usr/src/app/src/healthcheck.js
