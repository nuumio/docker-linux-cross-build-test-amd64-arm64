#!/bin/bash

ROUNDS=${ROUNDS:-10}
LINUXDIR=/linux-build/linux-5.0
LOGDIR=/linux-build/linux-5.0-log

function log {
    TIME=$(date "+%Y%m%d-%H%M%S")
    echo "*"
    echo "* ${TIME}: $@" | tee -a ${LOGDIR}/build-loop.txt
    echo "*"
}

function runit {
    cd ${LINUXDIR}
    if make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- mrproper allyesconfig vmlinux -j$(($(nproc)*3/2)); then
        true
    else
        false
    fi
}

mkdir -p ${LOGDIR}
rm ${LOGDIR}/*
log "Starting new loop"

OK=0
FAIL=0
for I in $(seq ${ROUNDS}); do
    R=$(printf "%03d" ${I})
    log "Round ${I} start"
    runit 2>&1 | tee ${LOGDIR}/build-log-${R}.txt
    if [[ "${PIPESTATUS[0]}" -eq 0 ]]; then
        log "Round ${I} OK"
        OK=$((OK+1))
    else
        log "Round ${I} FAIL"
        FAIL=$((FAIL+1))
    fi
    log "Stats: Rounds = ${I} / ${ROUNDS}, ok = ${OK}, fail = ${FAIL}"
done

