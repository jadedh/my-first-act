# Dockerfile contains instructions how to build a Docker image that
# will contain all the code and configuration needed to run your actor.
# For a full Dockerfile reference,
# see https://docs.docker.com/engine/reference/builder/

# First, specify the base Docker image. Apify provides the following
# base images for your convenience:
#  apify/actor-node-basic (Node.js on Alpine Linux, small and fast)
#  apify/actor-node-chrome (Node.js + Chrome on Debian)
#  apify/actor-node-chrome-xvfb (Node.js + Chrome + Xvfb on Debian)
# For more information, see https://docs.apify.com/actor/build#base-images
# Note that you can use any other image from Docker Hub.
FROM node:14-slim

# Install latest chrome dev package and fonts to support major charsets (Chinese, Japanese, Arabic, Hebrew, Thai and a few others)
# Note: this installs the necessary libs to make the bundled version of Chromium that Puppeteer
# installs, work.
RUN apt-get update \
    && apt-get install -y wget gnupg \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst \
    && apt-get install -y vim \
    fonts-freefont-ttf libxss1 \
      --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# If running Docker >= 1.13.0 use docker run's --init arg to reap zombie processes, otherwise
# uncomment the following lines to have `dumb-init` as PID 1
# ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_x86_64 /usr/local/bin/dumb-init
# RUN chmod +x /usr/local/bin/dumb-init
# ENTRYPOINT ["dumb-init", "--"]

# Uncomment to skip the chromium download when installing puppeteer. If you do,
# you'll need to launch puppeteer with:
#     browser.launch({executablePath: 'google-chrome-stable'})
# ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true

# Second, copy just package.json since it should be the only file
# that affects "npm install" in the next step, to speed up the build
COPY package.json ./

# Install NPM packages, skip optional and development dependencies to
# keep the image small. Avoid logging too much and print the dependency
# tree for debugging
RUN npm --quiet set progress=false \
    && npm install --only=prod --no-optional \
    && echo "Installed NPM packages:" \
    && npm list || true \
    && echo "Node.js version:" \
    && node --version \
    && echo "NPM version:" \
    && npm --version \
    && npm install puppeteer \
    # Add user so we don't need --no-sandbox.
    # same layer as npm install to keep re-chowned files from using up several hundred MBs more space
    && groupadd -r pptruser && useradd -r -g pptruser -G audio,video pptruser \
    && mkdir -p /home/pptruser/Downloads \
    && chown -R pptruser:pptruser /home/pptruser \
    && chown -R pptruser:pptruser /node_modules \
    && chown -R pptruser:pptruser /package.json \
    && chown -R pptruser:pptruser /package-lock.json

# Resolves Error: EACCES: permission denied
# USER root
# Run everything after as non-privileged user.
USER pptruser

# Next, copy the remaining files and directories with the source code.
# Since we do this after NPM install, quick build will be really fast
# for most source file changes.
# Note that because we are also copying the "apify_storage" directory, we
# need to set a correct owner to make it writable, for local runs in Docker.
COPY --chown=myuser . ./

# Optionally, specify how to launch the source code of your actor.
# By default, Apify's base Docker images define the CMD instruction
# that runs the Node.js source code using the command specified
# in the "scripts.start" section of the package.json file.
# In short, the instruction looks something like this:
#
# CMD node main.js
