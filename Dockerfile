FROM ubuntu:bionic
MAINTAINER Jari Hämäläinen <nuum.io.fi@gmail.com> (https://github.com/nuumio)

# Install tools
RUN set -ex \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        bc \
        bison \
        build-essential \
        ca-certificates \
        crossbuild-essential-arm64 \
        curl \
        flex \
        libssl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/*

# Get Linux source and make a volume out of build dir
RUN set -ex \
    && mkdir /linux-build \
    && cd /linux-build \
    && curl -LO https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.0.tar.xz \
    && tar xf linux-5.0.tar.xz \
    && rm linux-5.0.tar.xz
VOLUME /linux-build

# Entry point and stuff
ADD provisioning/build-loop.sh /usr/local/bin/build-loop.sh
RUN chmod +x /usr/local/bin/build-loop.sh
CMD ["/usr/local/bin/build-loop.sh"]

