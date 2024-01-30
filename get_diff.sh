#!/bin/bash

# 获取环境变量
env=$(sed -n '1p' env.txt)
start_date=$(sed -n '2p' env.txt)

# 获取localhost_hex_number
localhost_hex_number=$(curl -sS -X POST -H "Content-Type: application/json" -d '{"id": 1, "jsonrpc": "2.0", "method": "get_tip_header", "params": []}' http://localhost:8114 | jq -r '.result.number' | sed 's/^0x//')
if [[ $? -ne 0 || -z "$localhost_hex_number" ]]; then
    localhost_number="获取失败"
else
    localhost_number=$((16#$localhost_hex_number))
fi

# 获取mainnet或testnnet的hex_number
hex_number=$(curl -sS -X POST -H "Content-Type: application/json" -d '{"id": 1, "jsonrpc": "2.0", "method": "get_tip_header", "params": []}' https://${env}.ckbapp.dev | jq -r '.result.number' | sed 's/^0x//')
if [[ $? -ne 0 || -z "$hex_number" ]]; then
    number="获取失败"
else
    number=$((16#$hex_number))
fi

# 计算差值或指出无法计算
if [[ $localhost_number =~ ^[0-9]+$ && $number =~ ^[0-9]+$ ]]; then
    difference=$(($number - $localhost_number))
    if [[ $difference -lt 0 ]]; then
        difference=$((-$difference)) # 转换为绝对值
    fi
    sync_rate=$(echo "scale=10; $localhost_number * 100 / $number" | bc | awk '{printf "%.2f\n", $0}')
    sync_rate="${sync_rate}%"
else
    difference="无法计算"
    sync_rate="无法计算"
fi

echo "$(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S") localhost_number: ${localhost_number} ${env}_number: ${number} difference: ${difference}" sync_rate: ${sync_rate} >>diff_${start_date}.log

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

killckb() {
    PROCESS=$(ps -ef | grep /ckb | grep -v grep | awk '{print $2}' | sed -n '2,10p')
    for i in $PROCESS; do
        echo "killed the ckb $i"
        sudo kill -9 $i
    done
}

toggle_env() {
    local first_line=$(head -n 1 env.txt)

    if [ "$first_line" = "testnet" ]; then
        # 如果第一行是 testnet，则替换为 mainnet
        sed -i "1s/.*/mainnet/" env.txt
    elif [ "$first_line" = "mainnet" ]; then
        # 如果第一行是 mainnet，则替换为 testnet
        sed -i "1s/.*/testnet/" env.txt
    else
        echo "第一行既不是mainnet也不是testnet，未做任何更改"
    fi
}

# 检查是否存在sync_end且不存在kill_time
if grep -q "sync_end" result_${start_date}.log && ! grep -q "kill_time" result_${start_date}.log; then
    # 获取sync_end的Unix时间戳
    sync_end_time_str=$(grep 'sync_end' result_2024-01-30.log | cut -d' ' -f2-)
    sync_end_timestamp_utc=$(date -u -d "$sync_end_time_str" +%s)
    # 调整时区差异（减去8小时）
    sync_end_timestamp=$((sync_end_timestamp_utc - 8 * 3600))

    # 获取当前时间
    current_timestamp=$(TZ='Asia/Shanghai' date +%s)
    # 计算时间差（单位：秒）
    time_diff=$((current_timestamp - sync_end_timestamp))

    # 检查时间差是否超过6小时 (6小时 = 21600秒)
    if [[ $time_diff -gt 21600 ]]; then
        # 调用killckb函数并记录kill_time
        killckb
        echo "kill_time: $(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")" >>result_${start_date}.log
        toggle_env
    fi
fi
