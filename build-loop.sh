#!/bin/bash

ROUNDS=${ROUNDS:-30}
JOBS=${JOBS:-$(($(nproc)*3/2))}

# Docker check from: https://github.com/envkey/envkey-source/blob/4b61831b04a008325b9700f061b719a3c8ca7024/install.sh
if [[ "$(cat /proc/1/cgroup 2> /dev/null | grep docker | wc -l)" > 0 ]] || [ -f /.dockerenv ]; then
    IS_DOCKER=true
else
    IS_DOCKER=false
fi

# If not in Docker try to find kernel from current dir. Download is necessary.
if ! ${IS_DOCKER}; then
    KERNELVERSION=${KERNELVERSION:-nuumio-4.4-pcie-scan-sleep-01}
    KERNELNAME=${KERNELNAME:-linux-kernel}
    KERNELDIR=${KERNELNAME}-${KERNELVERSION}
    if [ -d ${KERNELDIR} ] && [ -f ${KERNELDIR}/Kconfig ] && [ -f ${KERNELDIR}/Makefile ]; then
        LINUXDIR=${PWD}/${KERNELDIR}
    elif [ -f Kconfig ] && [ -f Makefile ]; then
        LINUXDIR=${PWD}
    else
        echo "Downloading kernel source"
        curl -LO https://github.com/nuumio/linux-kernel/archive/${KERNELVERSION}.zip
        unzip ${KERNELVERSION}.zip
        LINUXDIR=${PWD}/${KERNELDIR}
    fi
    LOGDIR=${PWD}/build-logs
    mkdir -p ${LOGDIR}
fi

function log {
    TIME=$(date "+%Y%m%d-%H%M%S")
    echo "* ${TIME}: $@" | tee -a ${LOGDIR}/build-loop.txt
}

function runit {
    cd ${LINUXDIR}
    echo "Build INCOMPLETE" > /tmp/build-status.txt
    if make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- mrproper rockchip_linux_defconfig all -j${JOBS}; then
        echo "Build OK" | tee /tmp/build-status.txt
        true
    else
        echo "Build FAIL" | tee /tmp/build-status.txt
        false
    fi
}

mkdir -p ${LOGDIR}
rm -f ${LOGDIR}/*
log "Starting new loop of ${ROUNDS} rounds. Using ${JOBS} jobs."
if ${IS_DOCKER}; then
    log "Tail build loop log: docker exec $(hostname) tail -f ${LOGDIR}/build-loop.txt"
else
    log "Tail build loop log: tail -f ${LOGDIR}/build-loop.txt"
fi

OK=0
FAIL=0
for I in $(seq ${ROUNDS}); do
    RSTR="$(printf "Round %3d / %3d" ${I} ${ROUNDS})"
    RFILE="$(printf "%03d" ${I})"
    LOGFILE="${LOGDIR}/build-log-${RFILE}.txt"

    # See: https://serverfault.com/a/175400
    exec 3>&1 4>&2
    RTIME=$(TIMEFORMAT="%R"; { time (runit 2>&1 | tee ${LOGFILE} 1>&3 2>&4;) ; } 2>&1)
    exec 3>&- 4>&-
    BUILD_STATUS=$(cat /tmp/build-status.txt)
    LOGINFO=", took ${RTIME} seconds"
    if [ "${BUILD_STATUS}" = "Build OK" ]; then
        RES="$(echo "${RSTR} OK    ")"
        OK=$((OK+1))
    else
        RES="$(echo "${RSTR} FAIL  ")"
        FAIL=$((FAIL+1))
        LOGINFO="${LOGINFO}, log: ${LOGFILE}"
    fi

    STROK="$(printf "%3d" ${OK})"
    STRFAIL="$(printf "%3d" ${FAIL})"
    log "$(echo "${RES} Stats: ok = ${STROK}, fail = ${STRFAIL}${LOGINFO}")"
done

log "All done!"
# If in Docker wait for enter to exit scipt and the container.
# Makes it easier to grab logs after completing the loop.
if ${IS_DOCKER}; then
    read -p "Press enter to continue"
fi
