# 使用Alpine Linux作为基础镜像
FROM alpine:latest

# 更新软件包仓库索引并安装下面的工具
RUN apk update && \
    apk add --no-cache bash curl jq iputils tzdata dcron vim

# 设置工作目录
WORKDIR /app

# 设置时区
ENV TZ=Asia/Shanghai

# 使用一个持续运行的命令来保持容器活跃
CMD ["sh", "-c", "trap : TERM INT; sleep infinity & wait"]
