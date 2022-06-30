provider "cloudflare" {
  
  api_key = "28bb5f783edfc730d4aeea3104d4f1545c687"
  email   = "musa.hstu11@gmail.com"

}

locals {
  account = "0b18728259c1147a4cc82efe9538a2ec"
  domain  = "akmusa.tk"
}

resource "random_id" "argo_secret" {
  byte_length = 35
}


resource "cloudflare_argo_tunnel" "example" {
  account_id = local.account
  name       = var.tunnel_name
  secret     = random_id.argo_secret.b64_std

  provisioner "local-exec" {
    command = "/bin/bash credential_json_creator.sh ${cloudflare_argo_tunnel.example.account_id} ${cloudflare_argo_tunnel.example.secret} ${cloudflare_argo_tunnel.example.id} ${cloudflare_argo_tunnel.example.name}"

  }

}

# !!!!!!!!! Add a record to the domain !!!!!!!!!!1
## tried to add cname using resource but it's not supported for some TLDs(.ml, .tk etc) like my domain: akmusa.tk
/*
resource "cloudflare_record" "cname" {
  zone_id = var.cloudflare_zone_id
  name    = local.domain
  value   = cloudflare_argo_tunnel.example.cname
  type    = "CNAME"
  ttl     = 1
} */

resource "null_resource" "copy_files" {
  depends_on = [cloudflare_argo_tunnel.example] 
  provisioner "local-exec" {
    command = "mkdir ~/.cloudflared && cp credential.json ~/.cloudflared/credential.json && cp cert.pem ~/.cloudflared/cert.pem"
  }
}

resource "null_resource" "null" {
  depends_on = [null_resource.copy_files]  
  provisioner "local-exec" {
    command = "/bin/bash cloudflared_installer.sh ${cloudflare_argo_tunnel.example.id}"
  }

} 

resource "null_resource" "copy_files2" {
  depends_on = [null_resource.null] 
  provisioner "local-exec" {
    command = "mv config.yml ~/.cloudflared/ && cloudflared tunnel route dns ${cloudflare_argo_tunnel.example.name} ${local.domain}"
    }
}

resource "null_resource" "invokek8s" {
  depends_on = [null_resource.copy_files2]
  provisioner "local-exec" {
    command = "sed -i 's#tunnel:.*#tunnel: ${cloudflare_argo_tunnel.example.name}#g' ../k8s_manifest/cloudflared_manifest.yml && /bin/bash invoke_k8s.sh"
  }
}
