FROM ubuntu:bionic
LABEL author="Jari Hämäläinen <nuum.io.fi@gmail.com>"
LABEL homepage="https://github.com/nuumio/docker-linux-cross-build-test-amd64-arm64"

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
        less \
        libssl-dev \
        python \
        unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/*

# Default image environment
ENV KERNELVERSION nuumio-4.4-pcie-scan-sleep-01
ENV KERNELNAME linux-kernel
ENV BUILDDIR /linux-build
ENV LINUXDIR ${BUILDDIR}/${KERNELNAME}-${KERNELVERSION}
ENV LOGDIR ${BUILDDIR}/logs

# Get Linux source and make a volume out of build dir
RUN set -ex \
    && mkdir ${BUILDDIR} \
    && cd ${BUILDDIR} \
    && curl -LO https://github.com/nuumio/linux-kernel/archive/${KERNELVERSION}.zip \
    && unzip ${KERNELVERSION}.zip \
    && rm ${KERNELVERSION}.zip
VOLUME ${BUILDDIR}

# Add build loop itself
ADD build-loop.sh /usr/local/bin/build-loop.sh
RUN chmod +x /usr/local/bin/build-loop.sh
CMD ["/usr/local/bin/build-loop.sh"]

