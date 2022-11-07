# ------------------------
# Provider Config
# ------------------------
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.region
}

# Retrieve My Public IP
provider "http" {}

# ------------------------
# Variable Config
# ------------------------
variable "az_a" {
  default = "ap-northeast-1a"
}

variable "access_key" {
  description = "Access key of your AWS user account"
}

variable "secret_key" {
  description = "Secret key of your AWS user account"
}

variable "region" {
  default = "ap-northeast-1"
}

variable "instance_type" {
  type = string
  description = "(Optinal) The type of instance"
  default = "t2.medium"
}

variable "volume_size" {
  type = string
  description = "(Optinal) The size of the volume in gibibytes(GiB)"
  default = "50"
}

# ------------------------
# VPC Config
# ------------------------
# VPC
resource "aws_vpc" "htbkali_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true  # Enable DNS Host Name
  tags = {
    Name = "terraform-htbkali-vpc"
  }
}

# Subnet
resource "aws_subnet" "htbkali_public_1a_sn" {
  vpc_id = aws_vpc.htbkali_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.az_a}"
  tags = {
    Name = "terraform-htbkali-public-1a-sn"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "htbkali_igw" {
  vpc_id = aws_vpc.htbkali_vpc.id
  tags = {
    Name = "terraform-htbkali-igw"
  }
}

# Route Table
resource "aws_route_table" "htbkali_public_rt" {
  vpc_id = aws_vpc.htbkali_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.htbkali_igw.id
  }
  tags = {
    Name = "terraform-htbkali-public-rt"
  }
}

resource "aws_route_table_association" "htbkali_public_rt_associate" {
  subnet_id = aws_subnet.htbkali_public_1a_sn.id
  route_table_id = aws_route_table.htbkali_public_rt.id
}

# Security Group
data "http" "ifconfig" {
  url = "http://ipv4.icanhazip.com/"
}

variable "allowed_cidr" {
  default = null
}

locals {
  myip = chomp(data.http.ifconfig.response_body)
  allowed_cidr = (var.allowed_cidr == null) ? "${local.myip}/32" : var.allowed_cidr
}

resource "aws_security_group" "htbkali_ec2_sg" {
  name = "terraform-htbkali-ec2-sg"
  description = "For EC2 Linux"
  vpc_id = aws_vpc.htbkali_vpc.id
  tags = {
    Name = "terraform-htbkali-ec2-sg"
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [local.allowed_cidr]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------
# EC2 Config
# ------------------------
# Key Pair
variable "key_name" {
  default = "terraform-htbkali-keypair"
}

resource "tls_private_key" "htbkali_private_key" {
  algorithm = "RSA"
  rsa_bits = 2048
}

locals {
  public_key_file = "/home/vagrant/tf/${var.key_name}.id_rsa.pub"
  private_key_file = "/home/vagrant/tf/${var.key_name}.id_rsa"
}

resource "local_file" "htbkali_private_key_pem" {
  filename = "${local.private_key_file}"
  content = "${tls_private_key.htbkali_private_key.private_key_pem}"
  file_permission = "0400"
}

resource "aws_key_pair" "htbkali_keypair" {
  key_name = "${var.key_name}"
  public_key = "${tls_private_key.htbkali_private_key.public_key_openssh}"
}

# EC2
resource "aws_instance" "htbkali_ec2" {
  ami = "ami-079a7f1c97ababaaa"
  instance_type = "${var.instance_type}"
  availability_zone = "${var.az_a}"
  vpc_security_group_ids = [aws_security_group.htbkali_ec2_sg.id]
  subnet_id = aws_subnet.htbkali_public_1a_sn.id
  associate_public_ip_address = true
  key_name = "${var.key_name}"
  tags = {
    Name = "terraform-htbkali-ec2"
  }

  # root_block_device {
  #   volume_size = "${var.volume_size}"
  # }
}

# ------------------------
# Output Config
# ------------------------
output "ssh_ec2_kali_linux_connect" {
  value = "ssh -i ${local.private_key_file} kali@${aws_instance.htbkali_ec2.public_ip}"
}
