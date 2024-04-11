#!/bin/bash

function kill_ckb() {
    PROCESS=$(ps -ef | grep /ckb | grep -v grep | awk '{print $2}' | sed -n '2,10p')
    for i in $PROCESS; do
        echo "killed the ckb $i"
        sudo kill $i
    done
}

function kill9_ckb() {
    PROCESS=$(ps -ef | grep /ckb | grep -v grep | awk '{print $2}' | sed -n '2,10p')
    for i in $PROCESS; do
        echo "killed the ckb $i"
        sudo kill -9 $i
    done
}

function pkill_ckb() {
    sudo pkill ckb
}

function stop_service() {
    echo "Stopping the service..."

    case "$0" in
    "kill")
        kill_ckb
        ;;
    "kill9")
        kill9_ckb
        ;;
    "pkill")
        pkill_ckb
        ;;
    *)
        echo "Invalid argument. Usage: $0 [kill|kill9|pkill]"
        exit 1
        ;;
    esac

    exit 0
}
