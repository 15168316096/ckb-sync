#!/bin/bash

echo "666"

# # 定义函数
# killckb() {
#     PROCESS=$(ps -ef | grep /ckb | grep -v grep | awk '{print $2}' | sed -n '2,10p')
#     for i in $PROCESS; do
#         echo "killed the ckb $i"
#         sudo kill -9 $i
#     done
# }

# toggle_bool() {
#     # 获取 env.txt 文件的第三行
#     local third_line=$(sed -n '3p' env.txt)

#     if [ "$third_line" = "1" ]; then
#         # 如果第三行是 1，则替换为 0
#         sed -i "3s/.*/0/" env.txt
#     elif [ "$third_line" = "0" ]; then
#         # 如果第三行是 0，则替换为 1
#         sed -i "3s/.*/1/" env.txt
#     else
#         echo "第三行既不是1也不是0，未做任何更改"
#     fi
# }

# if [ ! -f "env.txt" ]; then
#     echo "env.txt，使用默认环境'mainnet'"
#     echo "mainnet" >env.txt
#     echo "2024-01-01" >>env.txt
#     echo "1" >>env.txt
# fi

# # 判断当天是否需要执行
# third_line=$(sed -n '3p' env.txt)
# if [ "$third_line" = "0" ]; then
#     # 如果第三行是 0，则打印信息并退出
#     echo "无需执行"
#     toggle_bool
#     exit 0
# else
#     # 如果第三行是 1，则打印信息并继续执行
#     echo "开始执行"
#     toggle_bool
# fi

# # 从env中选取testnet或mainnet，以及写入当前日期到env.txt
# env=$(sed -n '1p' env.txt)
# start_date=$(TZ='Asia/Shanghai' date "+%Y-%m-%d")
# sed -i "2s/.*/$start_date/" env.txt

# ckb_version=$(curl -s https://api.github.com/repos/nervosnetwork/ckb/releases/latest | jq -r '.tag_name')
# tar_name="ckb_${ckb_version}_x86_64-unknown-linux-gnu.tar.gz"

# if [ ! -f "$tar_name" ]; then
#     wget "https://github.com/nervosnetwork/ckb/releases/download/${ckb_version}/${tar_name}"
# fi

# # sudo rm -rf ckb_*_x86_64-unknown-linux-gnu
# # tar xzvf ${tar_name}
# cd ckb_${ckb_version}_x86_64-unknown-linux-gnu

# killckb

# # 初始化节点
# ./ckb --version >../result_${start_date}.log
# ./ckb init --chain ${env}
# echo "------------------------------------------------------------"
# grep 'spec =' ckb.toml >>../result_${start_date}.log

# # 修改ckb.toml
# grep "^listen_address =" ckb.toml
# new_listen_address="0.0.0.0:8114"
# sed -i "s/^listen_address = .*/listen_address = \"$new_listen_address\"/" ckb.toml
# grep "^listen_address =" ckb.toml

# grep "^modules =" ckb.toml
# new_module="\"Indexer\""
# sed -i "/^modules = .*/s/\]/, $new_module\]/" ckb.toml
# grep "^modules =" ckb.toml

# config_content="
# [metrics.exporter.prometheus]
# target = { type = \"prometheus\", listen_address = \"0.0.0.0:8100\" }

# # # Experimental: Monitor memory changes.
# [memory_tracker]
# # # Seconds between checking the process, 0 is disable, default is 0.
# interval = 5
# "
# echo "$config_content" >>ckb.toml
# tail -n 8 ckb.toml

# # 启动节点
# sudo nohup ./ckb run >/dev/null 2>&1 &
# sync_start=$(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")
# echo "sync_start: ${sync_start}" >>../result_${start_date}.log
