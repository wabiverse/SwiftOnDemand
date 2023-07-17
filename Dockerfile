
# ================================
# Build image
# ================================
FROM public.ecr.aws/docker/library/swift:latest as build

# Install OS updates and, if needed, sqlite3
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -y install libssl-dev \
    && apt-get -q install -y ca-certificates \
    && apt-get -q install -y tzdata \
    && apt-get -q install -y npm \
    && apt-get -q install -y curl \
    && apt-get -q install -y libcurl4 \
    && apt-get -q install -y libxml2 \
    && rm -rf /var/lib/apt/lists/*

# Set up a build area
WORKDIR /build

# Copy entire repo into container
COPY . .

# Install node dependencies.
RUN npm install

# Install precompiled wasm and swift.
RUN make prebuilt/wabt prebuilt/swift

# ================================
# Run image
# ================================
FROM public.ecr.aws/ubuntu/ubuntu:jammy

# Make sure all system packages are up to date, and install only essential packages.
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -q install -y \
      ca-certificates \
      tzdata \
      curl \
      libcurl4 \
      libxml2 \
      swift-doc \
      npm \
    && rm -r /var/lib/apt/lists/*

# Create a wabi user and group with /app as its home directory
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app wabi

# Switch to the new home directory
WORKDIR /app

# Copy built executable and any staged resources from builder
COPY --from=build --chown=wabi:wabi /build /app

# Ensure all further commands run as the wabi user
USER wabi:wabi

# Let Docker bind to port 3000
EXPOSE 3000

# Start the swift compiler service when the image is run, default to listening on port 3000.
ENTRYPOINT ["node"]
CMD ["./local_server.js"]
