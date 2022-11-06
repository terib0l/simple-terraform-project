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

# ------------------------
# VPC Config
# ------------------------
# VPC
resource "aws_vpc" "handson_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true  # Enable DNS Host Name
  tags = {
    Name = "terraform-handson-vpc"
  }
}

# Subnet
resource "aws_subnet" "handson_public_1a_sn" {
  vpc_id = aws_vpc.handson_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.az_a}"
  tags = {
    Name = "terraform-handson-public-1a-sn"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "handson_igw" {
  vpc_id = aws_vpc.handson_vpc.id
  tags = {
    Name = "terraform-handson-igw"
  }
}

# Route Table
resource "aws_route_table" "handson_public_rt" {
  vpc_id = aws_vpc.handson_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.handson_igw.id
  }
  tags = {
    Name = "terraform-handson-public-rt"
  }
}

resource "aws_route_table_association" "handson_public_rt_associate" {
  subnet_id = aws_subnet.handson_public_1a_sn.id
  route_table_id = aws_route_table.handson_public_rt.id
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

resource "aws_security_group" "handson_ec2_sg" {
  name = "terraform-handson-ec2-sg"
  description = "For EC2 Linux"
  vpc_id = aws_vpc.handson_vpc.id
  tags = {
    Name = "terraform-handson-ec2-sg"
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
  default = "terraform-handson-keypair"
}

resource "tls_private_key" "handson_private_key" {
  algorithm = "RSA"
  rsa_bits = 2048
}

locals {
  public_key_file = "/home/vagrant/tf/${var.key_name}.id_rsa.pub"
  private_key_file = "/home/vagrant/tf/${var.key_name}.id_rsa"
}

resource "local_file" "handson_private_key_pem" {
  filename = "${local.private_key_file}"
  content = "${tls_private_key.handson_private_key.private_key_pem}"
}

resource "aws_key_pair" "handson_keypair" {
  key_name = "${var.key_name}"
  public_key = "${tls_private_key.handson_private_key.public_key_openssh}"
}

# EC2
data "aws_ssm_parameter" "amzn2_latest_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "handson_ec2" {
  ami = data.aws_ssm_parameter.amzn2_latest_ami.value
  instance_type = "t2.micro"
  availability_zone = "${var.az_a}"
  vpc_security_group_ids = [aws_security_group.handson_ec2_sg.id]
  subnet_id = aws_subnet.handson_public_1a_sn.id
  associate_public_ip_address = "true"
  key_name = "${var.key_name}"
  tags = {
    Name = "terraform-handson-ec2"
  }
}

# ------------------------
# Output Config
# ------------------------
output "ec2_global_ips" {
  value = "${aws_instance.handson_ec2.*.public_ip}"
}
output "my_ip" {
  value = "${local.myip}"
}
