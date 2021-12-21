variable "aws_region" {
  description = "Home AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_hapee_instance_type" {
  description = "Default AWS instance type for HAPEE nodes"
  type        = string
  default     = "t3.small"
}

variable "aws_web_instance_type" {
  description = "Default AWS instance type for Web nodes"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "SSH key pair to use in AWS"
  type        = string
  default     = "hapee-test"
}

variable "hapee_cluster_size" {
  description = "Size of HAPEE nodes cluster"
  type        = number
  default     = 2
}

variable "web_cluster_size" {
  description = "Size of Web nodes cluster"
  type        = number
  default     = 3
}

# HAPEE 1.7r1 Ubuntu Xenial 16.04 (20171024)
variable "hapee_aws_amis" {
  default = {
    "us-east-1" = "ami-5d489227"
  }
}

# Ubuntu Xenial 16.04 hvm ebs-ssd instance
variable "ubuntu_aws_amis" {
  default = {
    "us-east-1" = "ami-37991b4d"
  }
}
