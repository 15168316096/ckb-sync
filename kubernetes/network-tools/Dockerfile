# 使用Alpine Linux作为基础镜像
FROM alpine:latest

# 更新软件包仓库索引
RUN apk update

# 安装bash、curl、jq和iputils（包含ping）
RUN apk add --no-cache bash curl jq iputils

# 设置工作目录
WORKDIR /app

# 使用一个持续运行的命令来保持容器活跃
CMD ["sh", "-c", "trap : TERM INT; sleep infinity & wait"]
