#!/bin/bash 

### this script populates credential.json file to be stored in ~/.cloudflared directory

ACCOUNT_ID="${1}" 
TUNNEL_SECRET="${2}" 
TUNNEL_ID="${3}" 
TUNNEL_NAME="${4}"

touch credential.json

cat <<EOF > credential.json
 {
    "AccountTag"   : "${ACCOUNT_ID}",
    "TunnelID"     : "${TUNNEL_ID}",
    "TunnelName"   : "${TUNNEL_NAME}",
    "TunnelSecret" : "${TUNNEL_SECRET}" 
 }
EOF

