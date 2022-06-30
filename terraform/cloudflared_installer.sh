#!/bin/bash 

TUNNEL_ID="${1}"

if [[ ! $(which cloudflared) ]]
then
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared
    # allow execution
    chmod a+x cloudflared
    # move to the path
    sudo mv cloudflared /usr/local/bin/ 
fi  


#touch config.yml

cat <<EOF > config.yml
 tunnel: "${TUNNEL_ID}"
 credentials-file: $HOME/.cloudflared/credential.json
EOF
