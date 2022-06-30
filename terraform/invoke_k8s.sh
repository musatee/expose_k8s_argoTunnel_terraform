#!/bin/bash 

### this script create k8s objects from local system's shell 

## create secret for tunnel credential 
kubectl create ns ecare-prod
kubectl create secret generic tunnel-credentials --from-file=credentials.json=$HOME/.cloudflared/credential.json --namespace ecare-prod 

## deploy all k8s objects 
kubectl apply -f ../k8s_manifest/deployment_myapp.yml 
kubectl apply -f ../k8s_manifest/service_myapp.yml 
kubectl apply -f ../k8s_manifest/cloudflared_manifest.yml 
