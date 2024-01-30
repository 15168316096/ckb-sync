#!/bin/bash

# 获取localhost_hex_number
localhost_hex_number=$(curl -sS -X POST -H "Content-Type: application/json" -d '{"id": 1, "jsonrpc": "2.0", "method": "get_tip_header", "params": []}' http://localhost:8114 | jq -r '.result.number' | sed 's/^0x0\?//')
if [[ $? -ne 0 || -z "$localhost_hex_number" ]]; then
    localhost_number="获取失败"
else
    localhost_number=$((16#$localhost_hex_number))
fi

# 获取mainnet_hex_number
mainnet_hex_number=$(curl -sS -X POST -H "Content-Type: application/json" -d '{"id": 1, "jsonrpc": "2.0", "method": "get_tip_header", "params": []}' https://mainnet.ckbapp.dev | jq -r '.result.number' | sed 's/^0x0\?//')
if [[ $? -ne 0 || -z "$mainnet_hex_number" ]]; then
    mainnet_number="获取失败"
else
    mainnet_number=$((16#$mainnet_hex_number))
fi

# 计算差值或指出无法计算
if [[ $localhost_number =~ ^[0-9]+$ && $mainnet_number =~ ^[0-9]+$ ]]; then
    difference=$(($mainnet_number - $localhost_number))
    if [[ $difference -lt 0 ]]; then
        difference=$((-$difference)) # 转换为绝对值
    fi
    sync_rate=$(echo "scale=1; $localhost_number / $mainnet_number * 100" | bc)%
else
    difference="无法计算"
    sync_rate="无法计算"
fi

echo "$(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S") localhost_number: ${localhost_number} mainnet_number: ${mainnet_number} difference: ${difference}" sync_rate: ${sync_rate} >>diff.log

start_date=$(cat latest_start_date.txt)

# 检查sync_end是否存在，并且差值小于100
if ! grep -q "sync_end" result_${start_date}.log && [[ $difference =~ ^[0-9]+$ ]] && [[ $difference -lt 100 ]]; then
    sync_end=$(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")
    echo "sync_end: ${sync_end}" >>result_${start_date}.log

    # 从日志文件中读取开始时间
    sync_start=$(grep 'sync_start' result_${start_date}.log | cut -d' ' -f2-)

    # 将时间转换为秒
    start_sec=$(date -d "$sync_start" +%s)
    end_sec=$(date -d "$sync_end" +%s)

    # 计算时间差
    diff_sec=$((end_sec - start_sec))

    # 转换为天、小时、分钟和秒
    days=$((diff_sec / 86400))
    hours=$(((diff_sec % 86400) / 3600))
    minutes=$(((diff_sec % 3600) / 60))
    seconds=$((diff_sec % 60))

    echo "同步耗时：${days}天 ${hours}小时 ${minutes}分钟 ${seconds}秒" >>result_${start_date}.log
fi
