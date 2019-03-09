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
        python \
        unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/*

# Get Linux source and make a volume out of build dir
RUN set -ex \
    && mkdir /linux-build \
    && cd /linux-build \
    && curl -LO https://github.com/nuumio/linux-kernel/archive/nuumio-4.4-pcie-scan-sleep-01.zip \
    && unzip nuumio-4.4-pcie-scan-sleep-01.zip \
    && rm nuumio-4.4-pcie-scan-sleep-01.zip
VOLUME /linux-build

# Entry point and stuff
ADD provisioning/build-loop.sh /usr/local/bin/build-loop.sh
RUN chmod +x /usr/local/bin/build-loop.sh
CMD ["/usr/local/bin/build-loop.sh"]

