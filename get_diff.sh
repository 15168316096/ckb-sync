#!/bin/bash

localhost_hex_number=$(curl -sS -X POST -H "Content-Type: application/json" -d '{"id": 1, "jsonrpc": "2.0", "method": "get_tip_header", "params": []}' http://localhost:8114 | jq -r '.result.number' | sed 's/^0x0\?//')
if [[ $? -ne 0 || -z "$localhost_hex_number" ]]; then
    localhost_number="获取失败"
else
    localhost_number=$((16#$localhost_hex_number))
fi

# 获取 mainnet_hex_number
mainnet_hex_number=$(curl -sS -X POST -H "Content-Type: application/json" -d '{"id": 1, "jsonrpc": "2.0", "method": "get_tip_header", "params": []}' https://mainnet.ckbapp.dev | jq -r '.result.number' | sed 's/^0x0\?//')
if [[ $? -ne 0 || -z "$mainnet_hex_number" ]]; then
    mainnet_number="获取失败"
else
    mainnet_number=$((16#$mainnet_hex_number))
fi

# 计算差值或指出无法计算
if [[ $localhost_number != "获取失败" && $mainnet_number != "获取失败" ]]; then
    difference=$(( $mainnet_number - $localhost_number ))
    if [[ $difference -lt 0 ]]; then
        difference=$(( -$difference ))  # 转换为绝对值
    fi
else
    difference="无法计算"
fi

echo "localhost_number: ${localhost_number} mainnet_number: ${mainnet_number} difference: ${difference}" >> sync.log
