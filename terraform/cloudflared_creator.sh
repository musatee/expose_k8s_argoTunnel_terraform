#!/bin/bash 

if [[ -d ~/.cloudflared ]]
then 
    mv ~/.cloudflared ~/.cloudflared_bak$(date +%Y-%m-%d%T)
fi
mkdir ~/.cloudflared && cp credential.json ~/.cloudflared/credential.json && cp cert.pem ~/.cloudflared/cert.pem
