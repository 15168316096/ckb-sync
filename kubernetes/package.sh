#!/bin/bash

#环境清理
rm -rf ckb

rm -f Dockerfile

docker images --format '{{.Repository}}:{{.Tag}}' | grep '^nervos/ckb:' | while read -r image; do
    echo "Deleting image: $image"
    docker rmi "$image"
done

docker images --format '{{.Repository}}:{{.Tag}}' | grep '^ckb:' | while read -r image; do
    echo "Deleting image: $image"
    docker rmi "$image"
done

docker images --format '{{.Repository}}:{{.Tag}}' | grep '^registry.cn-hangzhou.aliyuncs.com/scz996/ckb:' | while read -r image; do
    echo "Deleting image: $image"
    docker rmi "$image"
done

# https://github.com/eval-exec/ckb/tree/exec/async
# 做ckb镜像
git clone https://github.com/eval-exec/ckb.git
cd ckb
git checkout exec/async
make docker

# 提取镜像名称和标签
ckb_image=$(docker images --format '{{.Repository}}:{{.Tag}}\t{{.CreatedAt}}' | grep '^nervos/ckb:' | sort -k 2 -r | head -n 1 | cut -f1)
echo $ckb_image

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
# 做我用的镜像
commit_version=$(git log -n 1 --pretty=format:"%h")
date=$(TZ='Asia/Shanghai' date "+%Y-%m-%d")
sudo docker build -t ckb:async-${date}-${commit_version} .

# 上传镜像
export DOCKER_PASSWORD=CkbSync02
echo $DOCKER_PASSWORD | docker login --username 肥宅小竹 --password-stdin registry.cn-hangzhou.aliyuncs.com
image_id=$(docker images | grep "ckb.*async-${date}-${commit_version}" | awk '{print $3}')
docker tag $image_id registry.cn-hangzhou.aliyuncs.com/scz996/ckb:async-${date}-${commit_version}
docker push registry.cn-hangzhou.aliyuncs.com/scz996/ckb:async-${date}-${commit_version}
