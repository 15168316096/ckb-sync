#!/bin/bash

if [ ! -f "env.txt" ]; then
    echo "env.txt，使用默认环境'mainnet'"
    echo "mainnet" >env.txt
    echo "2024-01-01" >>env.txt
    echo "1" >>env.txt
fi

day=$(TZ='Asia/Shanghai' date "+%Y-%m-%d")
current_time=$(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")
chmod +x stop_service.sh
# 判断当前是否需要执行
third_line=$(sed -n '3p' env.txt)
if [ "$third_line" != "1" ]; then
    # 如果第三行不是 1，则打印信息、重启ckb、退出
    echo "$current_time 无需执行仅重启"
    ./stop_service pkill
    sleep 300
    cd ckb_*_x86_64-unknown-linux-gnu
    sudo nohup ./ckb run >/dev/null 2>&1 &
    exit 0
else
    # 如果第三行是 1，则打印信息并继续执行
    echo "$current_time 开始执行"
fi

# 从env中选取testnet或mainnet，以及写入当前日期到env.txt
env=$(sed -n '1p' env.txt)
start_day=$day
sed -i "2s/.*/$start_day/" env.txt

#拉取、解压ckb tar包
ckb_version=$(curl -s https://api.github.com/repos/nervosnetwork/ckb/releases | jq -r '.[] | select(.tag_name | startswith("v0.115")) | .tag_name' | sort -V | tail -n 1)
tar_name="ckb_${ckb_version}_x86_64-unknown-linux-gnu.tar.gz"

if [ ! -f "$tar_name" ]; then
    wget -q "https://github.com/nervosnetwork/ckb/releases/download/${ckb_version}/${tar_name}"
fi

sudo rm -rf ckb_*_x86_64-unknown-linux-gnu
tar xzvf ${tar_name}
rm -f ${tar_name}
cd ckb_${ckb_version}_x86_64-unknown-linux-gnu

./stop_service pkill

# 初始化节点
./ckb --version >../result_${start_day}.log
sudo ./ckb init --chain ${env} --force
echo "------------------------------------------------------------"
grep 'spec =' ckb.toml
grep 'spec =' ckb.toml | cut -d'/' -f2 | cut -d'.' -f1 >>../result_${start_day}.log

# 修改ckb.toml
sed -i 's/cat  = \"info\"/filter = \"info,ckb=debug\"/' ckb.toml
grep "^listen_address =" ckb.toml
new_listen_address="0.0.0.0:8114"
sed -i "s/^listen_address = .*/listen_address = \"$new_listen_address\"/" ckb.toml
grep "^listen_address =" ckb.toml

grep "^modules =" ckb.toml
new_module="\"Indexer\""
sed -i "/^modules = .*/s/\]/, $new_module\]/" ckb.toml
grep "^modules =" ckb.toml

config_content="
[metrics.exporter.prometheus]
target = { type = \"prometheus\", listen_address = \"0.0.0.0:8100\" }

# # Experimental: Monitor memory changes.
[memory_tracker]
# # Seconds between checking the process, 0 is disable, default is 0.
interval = 5
"
echo "$config_content" >>ckb.toml
tail -n 8 ckb.toml

# 启动节点
sudo nohup ./ckb run | grep -E "ERROR ckb_chain | ERROR ckb_notify" > error.log 2>&1 &
sync_start=$(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")
echo "sync_start: ${sync_start}" >>../result_${start_day}.log

# 下次执行不再拉包启动ckb
cd ..
if [ "$third_line" = "1" ]; then
    # 如果第三行是 1，则替换为 0
    sed -i "3s/.*/0/" env.txt
fi
