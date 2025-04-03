#!/bin/bash

# ==========================================================
# Beam Node Installer Script - Created by DEPINspirationHUB
# ==========================================================

clear
echo "************************************************************"
echo "*                                                          *"
echo "*              Beam Node Installer Script                  *"
echo "*                                                          *"
echo "*  This script is created by DEPINspirationHUB and is      *"
echo "*  partially AI-generated. It is provided AS-IS without    *"
echo "*  any warranties or guarantees.                           *"
echo "*                                                          *"
echo "*  ⚠️ USE AT YOUR OWN RISK.                                *"
echo "*  I (DEPINspirationHUB) will not be held liable for any   *"
echo "*  issues, damages, or losses caused by running this script.*"
echo "*                                                          *"
echo "************************************************************"
echo ""

read -p "Do you agree to these terms and want to proceed? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "❌ Installation cancelled."
  exit 1
fi

echo "✅ Thank you. Proceeding with installation..."
sleep 1

# ==========================================================
# Begin Installation
# ==========================================================

echo "🚀 Installing AvalancheGo, Beam Subnet-EVM, and starting your node..."

# Install dependencies
sudo apt-get update && sudo apt-get install -y wget tar screen jq curl

# Fetch latest AvalancheGo release tag from GitHub
latest=$(curl -s https://api.github.com/repos/ava-labs/avalanchego/releases/latest | jq -r .tag_name)

# Download and install AvalancheGo
cd ~
wget -q https://github.com/ava-labs/avalanchego/releases/download/$latest/avalanchego-linux-amd64-$latest.tar.gz
tar -xzf avalanchego-linux-amd64-$latest.tar.gz
sudo mv avalanchego-$latest/* /usr/local/bin/
sudo chmod +x /usr/local/bin/avalanchego
rm -rf avalanchego-$latest avalanchego-linux-amd64-$latest.tar.gz

# Setup Beam Subnet-EVM
mkdir -p ~/subnetevm ~/.avalanchego/plugins ~/.avalanchego/configs
cd ~/subnetevm

# Fetch latest Subnet-EVM release dynamically
subnetevm_latest=$(curl -s https://api.github.com/repos/ava-labs/subnet-evm/releases/latest | jq -r .tag_name)

# Download and extract Subnet-EVM
wget -q https://github.com/ava-labs/subnet-evm/releases/download/${subnetevm_latest}/subnet-evm_${subnetevm_latest#v}_linux_amd64.tar.gz
tar -xzf subnet-evm_${subnetevm_latest#v}_linux_amd64.tar.gz
mv subnet-evm ~/.avalanchego/plugins/kLPs8zGsTVZ28DhP1VefPCFbCgS7o5bDNez8JUxPVw9E6Ubbz

# Create node.json config (optional but helpful)
echo '{ "track-subnets": "eYwmVU67LmSfZb1RwqCMhBYkFyG8ftxn6jAwqzFmxC9STBWLC", "partial-sync-primary-network": true }' > ~/.avalanchego/configs/node.json

# Add upgrade.json for Beam chain
mkdir -p ~/.avalanchego/configs/chains/2tmrrBo1Lgt1mzzvPSFt73kkQKFas5d1AP88tv9cicwoFp8BSn
cd ~/.avalanchego/configs/chains/2tmrrBo1Lgt1mzzvPSFt73kkQKFas5d1AP88tv9cicwoFp8BSn
wget -q https://raw.githubusercontent.com/BuildOnBeam/beam-subnet/main/subnets/beam-mainnet/upgrade.json

# Create systemd service for beamnode
sudo tee /etc/systemd/system/beamnode.service > /dev/null <<EOF
[Unit]
Description=Beam Node
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/avalanchego --track-subnets=eYwmVU67LmSfZb1RwqCMhBYkFyG8ftxn6jAwqzFmxC9STBWLC
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable beamnode
sudo systemctl restart beamnode

# Wait a bit for node to boot up
echo ""
echo "🕐 Waiting for node to start..."
sleep 5

# Fetch Node ID, BLS Public Key, and Proof of Possession
NODE_INFO=$(curl -s -X POST --data '{ "jsonrpc":"2.0", "id":1, "method":"info.getNodeID", "params":{} }' \
-H 'Content-Type: application/json' 127.0.0.1:9650/ext/info)

NODE_ID=$(echo "$NODE_INFO" | jq -r .result.nodeID)
BLS_KEY=$(echo "$NODE_INFO" | jq -r .result.nodePOP.publicKey)
BLS_PROOF=$(echo "$NODE_INFO" | jq -r .result.nodePOP.proofOfPossession)

# Show output nicely
echo ""
echo "🎉 Your Beam Node is up and running!"
echo ""
echo "🚀 Use the details below to register as a validator:"
echo "--------------------------------------------"
echo "🆔 Node ID:            $NODE_ID"
echo "🔑 BLS Public Key:     $BLS_KEY"
echo "🦾 Proof of Possession:$BLS_PROOF"
echo "--------------------------------------------"
echo ""
echo "📝 Copy and paste these into the Beam registration form."
echo "📺 To view live node logs, run: journalctl -u beamnode -f"

# Save validator info to a file
echo -e "Node ID: $NODE_ID\nBLS Public Key: $BLS_KEY\nProof of Possession: $BLS_PROOF" > ~/beam-node-info.txt
echo "📂 Your validator info has been saved to: ~/beam-node-info.txt"
