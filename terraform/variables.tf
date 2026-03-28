variable "region"          { default = "us-east-1" }
variable "ssh_cidr"        { default = "0.0.0.0/0" }   # restrict to your IP in production
variable "public_key_path" { default = "~/.ssh/id_rsa.pub" }
