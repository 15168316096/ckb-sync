#!/bin/bash

# 获取环境变量
env=$(sed -n '1p' env.txt)
start_day=$(sed -n '2p' env.txt)

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

echo "$(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S") localhost_number: ${localhost_number} ${env}_number: ${number} difference: ${difference}" sync_rate: ${sync_rate} >>diff_${start_day}.log

# 检查sync_end是否存在，并且差值小于总高度的1%
if ! grep -q "sync_end" result_${start_day}.log && [[ $difference =~ ^[0-9]+$ ]] && [[ $difference -lt 12000 ]]; then
    sync_end=$(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")
    echo "sync_end: ${sync_end}（当前高度：$localhost_number）" >>result_${start_day}.log

    # 从日志文件中读取开始时间
    sync_start=$(grep 'sync_start' result_${start_day}.log | cut -d' ' -f2-)

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

    echo "同步到最新高度耗时：${days}天 ${hours}小时 ${minutes}分钟 ${seconds}秒" >>result_${start_day}.log
fi

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

    case "$1" in
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

trap 'stop_service "$1"' INT

echo "Press Ctrl+C to stop the service..."

while :
do
    if pgrep ckb >/dev/null; then
        echo "ckb process is running..."
    else
        break
    fi
    sleep 1
done

wait

toggle_env() {
    # 获取 env.txt 文件的第一行和第三行
    local first_line=$(head -n 1 env.txt)
    local third_line=$(sed -n '3p' env.txt)

    if [ "$first_line" = "testnet" ]; then
        # 如果第一行是 testnet，则替换为 mainnet
        sed -i "1s/.*/mainnet/" env.txt
    elif [ "$first_line" = "mainnet" ]; then
        # 如果第一行是 mainnet，则替换为 testnet
        sed -i "1s/.*/testnet/" env.txt
    else
        echo "第一行既不是mainnet也不是testnet，未做任何更改"
    fi

    # 第三行置为 1
    sed -i "3s/.*/1/" env.txt
}

# 检查是否存在sync_end且不存在kill_time
if grep -q "sync_end" result_${start_day}.log && ! grep -q "kill_time" result_${start_day}.log; then
    # 获取sync_end的Unix时间戳
    sync_end_time_str=$(grep 'sync_end' result_${start_day}.log | awk -F'sync_end: |（当前高度' '{print $2}')
    sync_end_timestamp_utc=$(date -u -d "$sync_end_time_str" +%s)
    # 调整时区差异（减去8小时）
    sync_end_timestamp=$((sync_end_timestamp_utc - 8 * 3600))

    # 获取当前时间
    current_timestamp=$(TZ='Asia/Shanghai' date +%s)
    # 计算时间差（单位：秒）
    time_diff=$((current_timestamp - sync_end_timestamp))

    #获取同步开始时间戳
    sync_start_time=$(grep 'sync_start:' result_${start_day}.log | cut -d' ' -f2-)
    sync_start_timestamp_utc=$(date -u -d "$sync_start_time" +%s)
    # 调整时区差异（减去8小时）
    sync_start_timestamp=$(((sync_start_timestamp_utc - 8 * 3600) * 1000))

    # ckb停20分钟后再启动
    if [[ $time_diff -ge 3500 && $time_diff -le 3700 ]]; then
        stop_service pkill_ckb
        sleep 1200
        cd ckb_*_x86_64-unknown-linux-gnu
        sudo nohup ./ckb run >/dev/null 2>&1 &
    fi

    # 检查时间差是否超过8小时 (8小时 = 28800秒)
    if [[ $time_diff -gt 28800 ]]; then
        # 调用pkillckb函数并记录kill_time
        stop_service pkill_ckb
        echo "kill_time: $(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")（当前高度：$localhost_number）" >>result_${start_day}.log
        echo "详见：https://grafana-monitor.nervos.tech/d/pThsj6xVz/test?orgId=1&var-url=18.163.221.211:8100&from=${sync_start_timestamp}&to=${current_timestamp}000" >>result_${start_day}.log
        python3 sendMsg.py result_${start_day}.log
        toggle_env
    fi
fi
