// Set default AWS region. Pay attention to inventory/ec2.ini which should also use the same region.
variable "aws_region" {
  description = "Home AWS region"
  default     = "us-east-1"
}

// Default instance type for HAPEE LB instances. Obviously, something along m5.xlarge or c5.xlarge should be a perfect fit.
variable "aws_hapee_instance_type" {
  description = "Default AWS instance type for HAPEE nodes"
  default     = "t2.micro"
}

// Default instance type for Web backends. Typically m5.4xlarge and similar, depending on use case.
variable "aws_web_instance_type" {
  description = "Default AWS instance type for Web nodes"
  default     = "t2.micro"
}

// SSH pub key pair located on Amazon. Also set/used in ansible.cfg.
variable "key_name" {
  description = "SSH key pair to use in AWS"
  default     = "noprod-hapee-test"
}

// Typical size of Web cluster backends. It's reasonable to have more than 2.
variable "web_cluster_size" {
  description = "Size of Web nodes cluster"
  default     = 3
}
