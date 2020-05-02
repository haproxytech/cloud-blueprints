// The contents of this file are Copyright (c) 2019. HAProxy Technologies. All Rights Reserved.
// This file is subject to the terms and conditions defined in
// file 'LICENSE.txt', which is part of this source code package.
//
provider "aws" {
  region = var.aws_region
}

// Lookup latest HAPEE Ubuntu AMI (Ubuntu Bionic 18.04 + HAPEE 1.8r2 at this moment)
data "aws_ami" "hapee_aws_amis" {
  most_recent = true

  filter {
    name   = "product-code"
    values = ["483gxnuft87jy44d3q8n4kvt1"]
  }

  filter {
    name   = "name"
    values = ["hapee-ubuntu-bionic-amd64-hvm-1.8*"]
  }

  owners = ["aws-marketplace"]
}

// Lookup latest Ubuntu Bionic 18.04 AMI
data "aws_ami" "ubuntu_aws_amis" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

// Default VPC definition
resource "aws_vpc" "default" {
  cidr_block           = "20.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "hapee_test_vpc"
  }
}

// Default subnet definition; in real world this sould span over at least two AZ
resource "aws_subnet" "tf_test_subnet" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "20.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "hapee_test_subnet"
  }
}

// Define our IGW
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "hapee_test_ig"
  }
}

// Define our standard routing table
resource "aws_route_table" "r" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "hapee_test_route_table"
  }
}

// Routing table association for default subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.tf_test_subnet.id
  route_table_id = aws_route_table.r.id
}

// Security group for Web backends
resource "aws_security_group" "web_node_sg" {
  name        = "web_node_sg"
  description = "Instance Web SG: pass SSH, permit HTTP only from HAPEE"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.hapee_node_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  tags = {
    Name = "hapee_web_node_sg"
  }
}

// Security group for HAPEE LB nodes
resource "aws_security_group" "hapee_node_sg" {
  name        = "hapee_node_sg"
  description = "Instance HAPEE SG: pass SSH, HTTP, HTTPS and Dashboard traffic by default"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port   = 3
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "112"
    self      = true
  }

  ingress {
    from_port   = 9022
    to_port     = 9022
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  ingress {
    from_port   = 9023
    to_port     = 9023
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  tags = {
    Name = "hapee_node_sg"
  }
}

// IAM policy document - Assume role policy
data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

// IAM policy document - EIP permissions policy
data "aws_iam_policy_document" "eip_policy" {
  statement {
    sid = "1"

    actions = [
      "ec2:DescribeAddresses",
      "ec2:AllocateAddress",
      "ec2:ReleaseAddress",
      "ec2:DescribeInstances",
      "ec2:AssociateAddress",
      "ec2:DisassociateAddress",
      "ec2:DescribeNetworkInterfaces",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses",
    ]

    resources = ["*"]
  }
}

// IAM role - EIP role
resource "aws_iam_role" "eip_role" {
  name               = "hapee_eip_role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

// IAM role policy - EIP role policy
resource "aws_iam_role_policy" "eip_role_policy" {
  name   = "hapee_eip_role_policy"
  role   = aws_iam_role.eip_role.id
  policy = data.aws_iam_policy_document.eip_policy.json
}

// IAM instance profile - EIP instance profile
resource "aws_iam_instance_profile" "eip_instance_profile" {
  name = "hapee_instance_profile"
  role = aws_iam_role.eip_role.id
}

// Instance definition for Web backends
// Variable instance count
resource "aws_instance" "web_node" {
  count = var.web_cluster_size

  instance_type = var.aws_web_instance_type
  ami           = data.aws_ami.ubuntu_aws_amis.id
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.web_node_sg.id]
  subnet_id              = aws_subnet.tf_test_subnet.id

  user_data = <<EOF
  #cloud-config
  runcmd:
    - systemctl stop apt-daily.service
    - systemctl kill --kill-who=all apt-daily.service
    - systemctl stop apt-daily.timer
  
EOF


  tags = {
    Name = "hapee_web_node"
  }
}

// Instance definition for HAPEE LB nodes
// Static instance count at 2
resource "aws_instance" "hapee_node" {
  count = 2

  instance_type        = var.aws_hapee_instance_type
  ami                  = data.aws_ami.hapee_aws_amis.id
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.eip_instance_profile.id

  vpc_security_group_ids = [aws_security_group.hapee_node_sg.id]
  subnet_id              = aws_subnet.tf_test_subnet.id

  user_data = <<EOF
  #cloud-config
  runcmd:
    - systemctl stop apt-daily.service
    - systemctl kill --kill-who=all apt-daily.service
    - systemctl stop apt-daily.timer
    - systemctl stop apt-daily-upgrade.timer
  EOF

  tags = {
    Name = "hapee_lb_node"
  }
}

// EIP allocation for primary static address for each HAPEE LB instance
resource "aws_eip" "hapee_node_eip1" {
  count = 2
  network_interface = element(
    aws_instance.hapee_node.*.primary_network_interface_id,
    count.index,
  )
  vpc = true
}
