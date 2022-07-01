provider "cloudflare" {
  api_key = "28bb5f783edfc730d4aeea3104d4f1545c687"
  email   = "musa.hstu11@gmail.com"
}

provider "aws" {
  profile = "kaz"
  region  = var.aws_region
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

#resource "null_resource" "copy_files" {
#  depends_on = [cloudflare_argo_tunnel.example]
#  provisioner "local-exec" {
#    command = "mkdir ~/.cloudflared && cp credential.json ~/.cloudflared/credential.json && cp cert.pem ~/.cloudflared/cert.pem"
#  }
#}

#### creates .cloudflared if not already exists & copy cert.pem, credential.json files to it
resource "null_resource" "copy_files" {
  depends_on = [cloudflare_argo_tunnel.example]
  provisioner "local-exec" {
    #command = "/bin/bash if [[ -d ~/.cloudflared ]];then mv ~/.cloudflared ~/.cloudflared_bak$(date +%Y-%m-%d%T);else mkdir ~/.cloudflared && cp credential.json ~/.cloudflared/credential.json && cp cert.pem ~/.cloudflared/cert.pem;fi"
    command = "/bin/bash cloudflared_creator.sh"

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

module "vpc" {
  source = "./modules/vpc/"
}

### create cluster role 
resource "aws_iam_role" "cluster_role" {
  name = "cluster_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "eks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Created_By  = module.vpc.common_tags["Created_By"]
    Environment = module.vpc.common_tags["Environment"]
    Name        = "cluster_role"
  }
}

### attach aws managed policy arn it to cluster role 
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

### create node role 
resource "aws_iam_role" "node_role" {
  name = "node_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Created_By  = module.vpc.common_tags["Created_By"]
    Environment = module.vpc.common_tags["Environment"]
    Name        = "node_role"
  }
}

### attach aws managed policy arn it to node role 
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

#### create eks cluster 
resource "aws_eks_cluster" "kaz" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster_role.arn

  vpc_config {
    subnet_ids = [module.vpc.public_sub1.id, module.vpc.public_sub2.id, module.vpc.public_sub3.id]
  }
  depends_on = [aws_iam_role_policy_attachment.AmazonEKSClusterPolicy]
}

## create eks cluster node-group 
resource "aws_eks_node_group" "kaz_nodes" {
  cluster_name    = aws_eks_cluster.kaz.name
  node_group_name = "kaz_nodes"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = [module.vpc.public_sub1.id, module.vpc.public_sub2.id, module.vpc.public_sub3.id]
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
  depends_on = [aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
  ]
}

### from dependancy Here I've to additionally authenticate to aws using same credentials of named profile used in order to run kubernetes manifests
resource "null_resource" "setup_aws_configure" {
  provisioner "local-exec" {
    command = "aws configure set aws_access_key_id ${var.aws_access_key}; aws configure set aws_secret_access_key ${var.aws_secret_key}; aws configure set default.region ${var.aws_region}"
  }
  depends_on = [aws_eks_node_group.kaz_nodes]
}

resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${aws_eks_cluster.kaz.name} --region ${var.aws_region}"
  }
  depends_on = [null_resource.setup_aws_configure]

}

resource "null_resource" "invokek8s" {
  provisioner "local-exec" {
    command = "sed -i 's#tunnel:.*#tunnel: ${cloudflare_argo_tunnel.example.name}#g' ../k8s_manifest/cloudflared_manifest.yml && /bin/bash invoke_k8s.sh"
  }
  depends_on = [null_resource.update_kubeconfig]
}
