# Variables
variable "region" {
  default = "us-east-1"
}

data "aws_caller_identity" "current" {}

variable "protocol" {
  default="http://"
}

variable "home" {
  default="/index.php"
}

# Specify the provider, version, access details
provider "aws" {
  region  = var.region
  version = "~> 2.58"
}

provider "tls" {
  version = "~> 2.1"
}

terraform {
  required_version = ">= 0.11.8"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name   = "php_sg_web"
  vpc_id = aws_vpc.default.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our default security group to access the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name   = "php_sg_access"
  vpc_id = aws_vpc.default.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "web" {
  name = "php-elb"

  subnets         = [aws_subnet.default.id]
  security_groups = [aws_security_group.elb.id]
  instances       = [aws_instance.web.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

# Extract relevant ami
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Generate key pair.
resource "tls_private_key" "this" {
  algorithm = "RSA"
}

resource "aws_key_pair" "auth" {
  key_name   = "flux-test"
  public_key = tls_private_key.this.public_key_openssh
}

resource "aws_instance" "web" {
  connection {
    type        = "ssh"
    user        = "ec2-user"
    host        = self.public_ip
    timeout     = "10m"
    private_key = tls_private_key.this.private_key_pem
  }

  instance_type = "t2.micro"
  key_name      = aws_key_pair.auth.key_name
  ami           = data.aws_ami.ubuntu.id

  # Our Security group to allow HTTP and SSH access. same as elb one. 
  vpc_security_group_ids = [aws_security_group.default.id]

  # We're going to launch into the same subnet as our ELB. In a production environment it's more common to have a separate private subnet for backend instances.
  subnet_id = aws_subnet.default.id

  #install apache, mysql client, php
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /var/www/html/",
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo service httpd start",
      "sudo usermod -a -G apache centos",
      "sudo chown -R centos:apache /var/www",
      "sudo yum install -y mysql php php-mysql",
    ]
  }
  provisioner "file" { #copy the index file form local to remote
    source      = "${path.module}/web/index.php"
    destination = "/tmp/index.php"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/index.php /var/www/html/index.php"
    ]
  }

  provisioner "file" { #copy the config file form local to remote. routes http to https
    source      = "${path.module}/web/apache2.conf"
    destination = "/tmp/apache2.conf"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir /etc/apache2",
      "sudo mv /tmp/apache2.conf /etc/apache2/apache2.conf",
    ]
  }

  tags = {
    Project = "Flux7"
  }
}

output "public_access" {
  value = "${var.protocol}${aws_elb.web.dns_name}${var.home}"
}

# aws ec2 describe-instance-status | jq .InstanceStatuses[0]