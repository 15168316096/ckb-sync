#!/bin/bash

ckb_version=$(curl -s https://api.github.com/repos/nervosnetwork/ckb/releases/latest | jq -r '.tag_name')
tar_name="ckb_${ckb_version}_x86_64-unknown-linux-gnu.tar.gz"

if [ ! -f "$tar_name" ]; then
    wget "https://github.com/nervosnetwork/ckb/releases/download/${ckb_version}/${tar_name}"
fi

rm -rf ckb_*_x86_64-unknown-linux-gnu
tar xzvf ${tar_name}

killckb() {
    PROCESS=$(ps -ef | grep /ckb | grep -v grep | awk '{print $2}' | sed -n '2,10p')
    for i in $PROCESS; do
        echo "killed the ckb $i"
        sudo kill -9 $i
    done
}

killckb

start_date=$(TZ='Asia/Shanghai' date "+%Y-%m-%d")
echo $start_date >latest_start_date.txt
cd ckb_${ckb_version}_x86_64-unknown-linux-gnu
./ckb --version >../result_${start_date}.log
