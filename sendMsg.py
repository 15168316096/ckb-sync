import discord
import sys
from dotenv import load_dotenv
import os

# 加载环境变量
load_dotenv()

# 从环境变量中获取TOKEN和CHANNEL_ID
TOKEN = os.getenv("DISCORD_TOKEN")
CHANNEL_ID = int(os.getenv("DISCORD_CHANNEL_ID"))

# 确保传入了文件名参数
if len(sys.argv) < 2:
    print("使用方法: python3 sendMsg.py <文件名>")
    sys.exit(1)

# 获取文件名
file_name = sys.argv[1]

# 读取文件内容
try:
    with open(file_name, 'r') as file:
        message_content = file.read()
except FileNotFoundError:
    print(f"找不到文件: {file_name}")
    sys.exit(1)
except Exception as e:
    print(f"读取文件时出错: {e}")
    sys.exit(1)

intents = discord.Intents.default()
intents.message_content = True

# 声明一个客户端
client = discord.Client(intents=intents)


# 当客户端准备好时触发的事件处理器
@client.event
async def on_ready():
    print(f'已登录为 {client.user}')

    # 发送消息到指定的频道
    channel = client.get_channel(CHANNEL_ID)  # 替换为你要发送消息的频道 ID
    await channel.send(message_content)  # 发送读取的文件内容
    await client.close()


# 运行客户端
client.run(TOKEN)
