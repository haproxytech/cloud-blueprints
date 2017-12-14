provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_vpc" "default" {
  cidr_block           = "20.0.0.0/16"
  enable_dns_hostnames = true

  tags {
    Name = "hapee_test_vpc"
  }
}

resource "aws_subnet" "tf_test_subnet" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "20.0.0.0/24"
  map_public_ip_on_launch = true

  tags {
    Name = "hapee_test_subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "hapee_test_ig"
  }
}

resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "aws_route_table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.tf_test_subnet.id}"
  route_table_id = "${aws_route_table.r.id}"
}

resource "aws_security_group" "instance_sg1" {
  name        = "instance_sg1"
  description = "Instance (HAPEE/Web node) SG to pass tcp/22 by default"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 22
    to_port     = 22
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
}

resource "aws_security_group" "instance_sg2" {
  name        = "instance_sg2"
  description = "Instance (HAPEE/Web node) SG to pass ELB traffic  by default"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.instance_sg1.id}", "${aws_security_group.elb.id}"]
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = ["${aws_security_group.instance_sg1.id}", "${aws_security_group.elb.id}"]
  }
}

resource "aws_security_group" "elb" {
  name        = "elb_sg"
  description = "Used in the terraform"

  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_elb" "hapee_elb" {
  name = "hapee-test-elb"

  subnets = ["${aws_subnet.tf_test_subnet.id}"]

  security_groups = ["${aws_security_group.elb.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8080/haproxy_status"
    interval            = 30
  }

  instances                   = ["${aws_instance.hapee_node.*.id}"]
  cross_zone_load_balancing   = false
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "hapee_elb"
  }
}

resource "aws_proxy_protocol_policy" "proxy_http" {
  load_balancer  = "${aws_elb.hapee_elb.name}"
  instance_ports = ["80"]
}

resource "aws_instance" "web_node" {
  count = "${var.web_cluster_size}"

  instance_type = "${var.aws_web_instance_type}"

  ami = "${lookup(var.ubuntu_aws_amis, var.aws_region)}"

  key_name = "${var.key_name}"

  vpc_security_group_ids = ["${aws_security_group.instance_sg1.id}", "${aws_security_group.instance_sg2.id}"]
  subnet_id              = "${aws_subnet.tf_test_subnet.id}"
  user_data              = "${file("web-userdata.sh")}"

  tags {
    Name = "web_node_${count.index}"
  }
}

data "template_file" "hapee-userdata" {
  template = "${file("hapee-userdata.sh.tpl")}"

  vars {
    serverlist = "${join("\n", formatlist("    server app-%v %v:80 cookie app-%v check", aws_instance.web_node.*.id, aws_instance.web_node.*.private_ip, aws_instance.web_node.*.id))}"
  }
}

resource "aws_instance" "hapee_node" {
  count = "${var.hapee_cluster_size}"

  instance_type = "${var.aws_hapee_instance_type}"

  ami = "${lookup(var.hapee_aws_amis, var.aws_region)}"

  key_name = "${var.key_name}"

  vpc_security_group_ids = ["${aws_security_group.instance_sg1.id}", "${aws_security_group.instance_sg2.id}"]
  subnet_id              = "${aws_subnet.tf_test_subnet.id}"
  user_data              = "${data.template_file.hapee-userdata.rendered}"

  tags {
    Name = "hapee_node_${count.index}"
  }
}
