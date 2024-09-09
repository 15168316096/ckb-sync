#!/bin/bash

# 0x0000000000000000000000000000000000000000000000000000000000000000
assume_valid_target=""

# 定义函数
killckb() {
    PIDS=$(sudo lsof -ti:8114)
    for i in $PIDS; do
        echo "killed the ckb $i"
        sudo kill $i
    done
}

if [ ! -f "env.txt" ]; then
    echo "mainnet" >env.txt
    echo "2024-01-01" >>env.txt
    echo "1" >>env.txt
    echo "3" >>env.txt
fi

# 判断当前是否需要执行
if pgrep -f "./ckb replay" >/dev/null; then
    echo "'./ckb replay' is running"
    exit 0
fi

# 从env中选取testnet或mainnet，以及获取当前时间
env=$(sed -n '1p' env.txt)
current_time=$(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")

third_line=$(sed -n '3p' env.txt)
if [ "$third_line" != "1" ]; then
    # 如果第三行不是 1，则打印信息、重启ckb、退出
    echo "$current_time 无需执行仅重启"
    killckb
    sleep 300
    cd ${env}_ckb_*_x86_64-unknown-linux-gnu
    # 记录重启开始时间
    restart_time=$(date +%s)
    sudo nohup ./ckb run >/dev/null 2>&1 &
    while true; do
      # 检查端口上是否有进程
      if sudo lsof -i:8114 -t >/dev/null; then
        # 计算耗时
        end_time=$(date +%s)
        duration=$((end_time - restart_time))
        echo "重启耗时: ${duration}秒"
        break
      fi

      # 每秒检查一次
      sleep 1

      # 计算当前耗时
      current_time=$(date +%s)
      current_duration=$((current_time - restart_time))

      # 如果耗时超过60秒，则打印信息并退出循环
      if [ "$current_duration" -gt 60 ]; then
        echo "超时信息：重启过程耗时超过60秒"
        break
      fi
    done
    exit 0
else
    # 如果第三行是 1，则打印信息并继续执行
    echo "$current_time 开始执行"
fi

# 写入当前日期到env.txt
start_day=$(TZ='Asia/Shanghai' date "+%Y-%m-%d")
sed -i "2s/.*/$start_day/" env.txt

rich_indexer_type=$(sed -n '4p' env.txt)

#拉取、解压ckb tar包
ckb_version=$(
    curl -s https://api.github.com/repos/nervosnetwork/ckb/releases |
        jq -r '.[] | select(.tag_name | startswith("v0.118")) |
        {tag_name, published_at} | "\(.published_at) \(.tag_name)"' |
        sort |
        tail -n 1 |
        cut -d " " -f2
)
echo "Latest CKB version: $ckb_version"
tar_name="ckb_${ckb_version}_x86_64-unknown-linux-gnu.tar.gz"

if [ ! -f "$tar_name" ]; then
    wget -q "https://github.com/nervosnetwork/ckb/releases/download/${ckb_version}/${tar_name}"
fi

sudo rm -rf ${env}_ckb_*_x86_64-unknown-linux-gnu
tar xzvf ${tar_name}
rm -f ${tar_name}
mv ckb_${ckb_version}_x86_64-unknown-linux-gnu ${env}_ckb_${ckb_version}_x86_64-unknown-linux-gnu
cd ${env}_ckb_${ckb_version}_x86_64-unknown-linux-gnu
#rm -f ckb
#cp /home/ckb/scz/ckb/target/prod/ckb .

killckb

# 初始化节点
if [ -f "../result_${start_day}.log" ]; then
    # 如果文件存在，则删除文件
    rm -f ../result_${start_day}.log
    # 打印信息提示已删除
    echo "result_${start_day}.log已被删除"
fi
./ckb --version >../result_${start_day}.log
sudo ./ckb init --chain ${env} --force
echo "------------------------------------------------------------"
grep 'spec =' ckb.toml
grep 'spec =' ckb.toml | cut -d'/' -f2 | cut -d'.' -f1 >>../result_${start_day}.log

# 修改ckb.toml
grep "^listen_address =" ckb.toml
new_listen_address="0.0.0.0:8114"
sed -i "s/^listen_address = .*/listen_address = \"$new_listen_address\"/" ckb.toml
grep "^listen_address =" ckb.toml

grep "^modules =" ckb.toml
if [ "$rich_indexer_type" = "1" ] || [ "$rich_indexer_type" = "2" ]; then
    new_module="\"RichIndexer\""
else
    new_module="\"Indexer\""
fi
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

if [ "$rich_indexer_type" = "1" ]; then
    sudo systemctl stop postgresql
    sudo rm -rf /var/lib/postgresql/16/main
    sudo -u postgres /usr/lib/postgresql/16/bin/initdb -D /var/lib/postgresql/16/main
    sudo sed -i 's/scram-sha-256/trust/g' /etc/postgresql/16/main/pg_hba.conf
    sudo systemctl start postgresql
    sudo systemctl status postgresql
    sed -i '/^# \[indexer_v2\.rich_indexer\]/,/^# db_password = "123456"$/s/^# //' ckb.toml
fi

if [ "$rich_indexer_type" = "1" ]; then
    echo "rich-indexer type: PostgreSQL" >>../result_${start_day}.log
elif [ "$rich_indexer_type" = "2" ]; then
    echo "rich-indexer type: SQLite" >>../result_${start_day}.log
else
    echo "rich-indexer type: Not Enabled" >>../result_${start_day}.log
fi

# 启动节点
if [ -z "${assume_valid_target}" ]; then
    sudo nohup ./ckb run >/dev/null 2>&1 &
    # https://github.com/nervosnetwork/ckb/blob/develop/util/constant/src/default_assume_valid_target.rs
    echo "assume-valid-target: default" >>../result_${start_day}.log
else
    sudo nohup ./ckb run --assume-valid-target "$assume_valid_target" >/dev/null 2>&1 &
    echo "assume-valid-target: ${assume_valid_target}" >>../result_${start_day}.log
fi

echo "$(grep -c ^processor /proc/cpuinfo)C$(free -h | grep Mem | awk '{print $2}' | sed 's/Gi//')G    $(lsb_release -d | sed 's/Description:\s*//')    $(lscpu | grep "Model name" | cut -d ':' -f2 | xargs)" >>../result_${start_day}.log
sync_start=$(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")
echo "sync_start: ${sync_start}" >>../result_${start_day}.log

# 下次执行不再拉包启动ckb
cd ..
if [ "$third_line" = "1" ]; then
    # 如果第三行是 1，则替换为 0
    sed -i "3s/.*/0/" env.txt
fi
