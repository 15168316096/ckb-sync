#!/bin/bash

#环境清理
rm -rf ckb

rm -f Dockerfile

docker images --format '{{.Repository}}:{{.Tag}}' | grep '^nervos/ckb:' | while read -r image; do
    echo "Deleting image: $image"
    docker rmi "$image"
done

docker images --format '{{.Repository}}:{{.Tag}}' | grep '^registry.cn-hangzhou.aliyuncs.com/scz996/ckb:' | while read -r image; do
    echo "Deleting image: $image"
    docker rmi "$image"
done

# https://github.com/eval-exec/ckb/tree/exec/async
# 做镜像
git clone https://github.com/eval-exec/ckb.git
cd ckb
git checkout exec/async
make docker

# 上传镜像
commit_version=$(git log -n 1 --pretty=format:"%h")
date=$(TZ='Asia/Shanghai' date "+%Y-%m-%d")

export DOCKER_PASSWORD=CkbSync02
echo $DOCKER_PASSWORD | docker login --username 肥宅小竹 --password-stdin registry.cn-hangzhou.aliyuncs.com
image_id=$(docker images | awk '$1=="nervos/ckb" {print $3}')
docker tag $image_id registry.cn-hangzhou.aliyuncs.com/scz996/ckb:async-${date}-${commit_version}
docker push registry.cn-hangzhou.aliyuncs.com/scz996/ckb:async-${date}-${commit_version}
