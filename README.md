## Usage
```bash
# Start or restart ckb every two hours.
20 */2 * * * cd /home/ckb/scz/ckb-sync && sudo bash sync.sh >> sync.log 2>&1
# Statistics are collected every 20 minutes.
10,30,50 * * * * cd /home/ckb/scz/ckb-sync && sudo bash get_diff.sh >> get_diff.log 2>&1
```
## Instructions
Python3 and packages such as discord and python-dotenv need to be installed on the server for testing synchronization.
```bash
sudo apt-get install jq python3-pip -y
```
```bash
sudo pip install discord python-dotenv
```
Please configure the .env file for sending test reports.
```dotenv
DISCORD_CHANNEL_ID=YOUR_DISCORD_CHANNEL_ID
DISCORD_TOKEN=YOUR_DISCORD_TOKEN
```
## exit the SSH session
1. control + A
2. D
## Debug
If there are problems with CKB sync, you can use the following command and enable the debug configuration in the ckb.toml file to help identify the issue.
```bash
curl -s -X POST 127.0.0.1:8114  -H 'Content-Type: application/json' -d '{ "id": 42, "jsonrpc": "2.0", "method": "sync_state", "params": [] }' | jq
curl -s -X POST 127.0.0.1:8114  -H 'Content-Type: application/json' -d '{ "id": 42, "jsonrpc": "2.0", "method": "get_peers", "params": [] }' | jq | grep last_common_header_number
```
Line 13 of ckb.toml

`filter = "info,ckb=debug"`
