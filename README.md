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
