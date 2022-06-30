# Expose k8s service through argo tunnel or cloudflare tunnel using terraform

## It needs to have following packages installed on your local system 
***
	aws-cli 
	kubectl 
	terraform 

## Steps to follow along
1. create a named profile called "kaz" for terraform to interact with aws 
	
		$ aws configure set aws_access_key_id <access_key> --profile kaz 
		$ aws configure set aws_secret_access_key <secret_key> --profile kaz 
         
2. delete .cloudflared directory from your home direcotory if it already exists 

		$ rm -rf ~/.cloudflared 
3. Initialize terraform

		$ terraform init
		$ terraform apply --auto-approve 
		
It'll prompt aws_access_key & aws_secret_key . Provide accordingly what you've already use to create named profile "kaz" 
Also provide a <tunnel_name> when it prompts 

 
