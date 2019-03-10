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
        LOGDIR=${LINUXDIR}/build-logs
    elif [ -f Kconfig ] && [ -f Makefile ]; then
        LINUXDIR=${PWD}
        LOGDIR=${LINUXDIR}/build-logs
    else
        echo "Downloading kernel source"
        curl -LO https://github.com/nuumio/linux-kernel/archive/${KERNELVERSION}.zip
        unzip ${KERNELVERSION}.zip
        LINUXDIR=${PWD}/${KERNELDIR}
        LOGDIR=${LINUXDIR}/build-logs
    fi
    mkdir -p ${LOGDIR}
fi

function log {
    TIME=$(date "+%Y%m%d-%H%M%S")
    echo "* ${TIME}: $@" | tee -a ${LOGDIR}/build-loop.txt
}

function runit {
    cd ${LINUXDIR}
    if make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- mrproper rockchip_linux_defconfig all -j${JOBS}; then
        true
    else
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
sleep 1

OK=0
FAIL=0
for I in $(seq ${ROUNDS}); do
    RSTR="$(printf "Round %3d / %3d" ${I} ${ROUNDS})"
    RFILE="$(printf "%03d" ${I})"
    log "${RSTR} start"

    runit 2>&1 | tee ${LOGDIR}/build-log-${RFILE}.txt
    if [[ "${PIPESTATUS[0]}" -eq 0 ]]; then
        RES="$(echo "${RSTR} OK    ")"
        OK=$((OK+1))
    else
        RES="$(echo "${RSTR} FAIL  ")"
        FAIL=$((FAIL+1))
    fi

    STROK="$(printf "%3d" ${OK})"
    STRFAIL="$(printf "%3d" ${FAIL})"
    log "$(echo "${RES} Stats: ok = ${STROK}, fail = ${STRFAIL}")"
done

