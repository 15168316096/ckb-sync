#!/bin/bash

# 清理环境
rm -rf ckb
rm -f Dockerfile

# 删除本地的相关 Docker 镜像
docker images --format '{{.Repository}}:{{.Tag}}' | grep -E '^nervos/ckb:|^ckb:|^registry.cn-hangzhou.aliyuncs.com/scz996/ckb:' | while read -r image; do
    echo "Deleting image: $image"
    docker rmi "$image"
done

# 拉取 Docker 仓库的镜像
docker pull nervos/ckb:v0.118.0-rc1
ckb_image="nervos/ckb:v0.118.0-rc1"
echo "Using image: $ckb_image"

# 创建 Dockerfile
cat <<EOF >Dockerfile
FROM $ckb_image
USER root
RUN mkdir -p /var/lib/apt/lists/partial
RUN chmod -R 777 /var/lib/apt/lists
RUN apt-get update && apt-get install -y \\
    curl \\
    iputils-ping \\
    tmux
EOF

cat Dockerfile

version="118-rc1"

# 构建并标记新镜像
date=$(TZ='Asia/Shanghai' date "+%Y-%m-%d")
sudo docker build -t ckb:${version}-${date} .

# 上传镜像
export DOCKER_PASSWORD=CkbSync02
echo $DOCKER_PASSWORD | docker login --username 肥宅小竹 --password-stdin registry.cn-hangzhou.aliyuncs.com
image_id=$(docker images | grep "ckb.*${version}-${date}" | awk '{print $3}')
docker tag $image_id registry.cn-hangzhou.aliyuncs.com/scz996/ckb:${version}-${date}
docker push registry.cn-hangzhou.aliyuncs.com/scz996/ckb:${version}-${date}
