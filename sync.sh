#!/bin/bash

ckb_version=$(curl -s https://api.github.com/repos/nervosnetwork/ckb/releases/latest | jq -r '.tag_name')
tar_name="ckb_${ckb_version}_x86_64-unknown-linux-gnu.tar.gz"

if [ ! -f "$tar_name" ]; then
    wget "https://github.com/nervosnetwork/ckb/releases/download/${ckb_version}/${tar_name}"
fi

rm -rf ckb_${ckb_version}_x86_64-unknown-linux-gnu
tar xzvf ${tar_name}

start_date=$(TZ='Asia/Shanghai' date "+%Y-%m-%d")
echo $start_date >latest_start_date.txt
cd ckb_${ckb_version}_x86_64-unknown-linux-gnu
./ckb --version >sync_result_${start_date}.log
