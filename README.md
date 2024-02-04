## 用法
```bash
# 有8小时时差 每天9点半启动
30 1 * * * cd /home/ckb/scz/ckb-sync && sudo bash sync.sh >> sync.log 2>&1
# 每小时的10分、40分统计一次
10,40 * * * * cd /home/ckb/scz/ckb-sync && sudo bash get_diff.sh
```
## 说明
