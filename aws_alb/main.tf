provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "all" {
}

resource "aws_vpc" "default" {
  cidr_block           = "20.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "hapee_test_vpc"
  }
}

resource "aws_subnet" "tf_test_subnet" {
  count                   = var.aws_az_count
  vpc_id                  = aws_vpc.default.id
  cidr_block              = cidrsubnet(aws_vpc.default.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.all.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "hapee_test_subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "hapee_test_ig"
  }
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "aws_route_table"
  }
}

resource "aws_route_table_association" "a" {
  count          = var.aws_az_count
  subnet_id      = element(aws_subnet.tf_test_subnet.*.id, count.index)
  route_table_id = aws_route_table.r.id
}

resource "aws_security_group" "instance_sg1" {
  name        = "instance_sg1"
  description = "Instance (HAPEE/Web node) SG to pass tcp/22 by default"
  vpc_id      = aws_vpc.default.id

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
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.instance_sg1.id, aws_security_group.alb.id]
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.instance_sg1.id, aws_security_group.alb.id]
  }
}

resource "aws_security_group" "alb" {
  name        = "alb_sg"
  description = "Used in the terraform"

  vpc_id = aws_vpc.default.id

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

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_lb" "hapee_alb" {
  name = "hapee-test-alb"

  internal = false

  subnets         = aws_subnet.tf_test_subnet.*.id
  security_groups = [aws_security_group.alb.id]

  tags = {
    Name = "hapee_alb"
  }
}

resource "aws_lb_target_group" "hapee_alb_target" {
  name = "hapee-test-alb-tg"

  vpc_id = aws_vpc.default.id

  port     = 80
  protocol = "HTTP"

  health_check {
    interval            = 30
    path                = "/haproxy_status"
    port                = 8080
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200,202"
  }

  tags = {
    Name = "hapee_alb_tg"
  }
}

resource "aws_lb_listener" "hapee_alb_listener" {
  load_balancer_arn = aws_lb.hapee_alb.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.hapee_alb_target.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "hapee_alb_target_att" {
  count = var.hapee_cluster_size * var.aws_az_count

  target_group_arn = aws_lb_target_group.hapee_alb_target.arn
  target_id        = element(aws_instance.hapee_node.*.id, count.index)

  port = 80
}

resource "aws_instance" "web_node" {
  count = var.web_cluster_size * var.aws_az_count

  instance_type = var.aws_web_instance_type

  ami = var.ubuntu_aws_amis[var.aws_region]

  key_name = var.key_name

  vpc_security_group_ids = [aws_security_group.instance_sg1.id, aws_security_group.instance_sg2.id]
  subnet_id = element(
    aws_subnet.tf_test_subnet.*.id,
    //    count.index / var.web_cluster_size,
    count.index
  )
  user_data = file("web-userdata.sh")

  tags = {
    Name = "web_node_${count.index}"
  }
}

data "template_file" "hapee-userdata" {
  template = file("hapee-userdata.sh.tpl")

  vars = {
    serverlist = join(
      "\n",
      formatlist(
        "    server app-%v %v:80 cookie app-%v check",
        aws_instance.web_node.*.id,
        aws_instance.web_node.*.private_ip,
        aws_instance.web_node.*.id,
      ),
    )
  }
}

resource "aws_instance" "hapee_node" {
  count = var.hapee_cluster_size * var.aws_az_count

  instance_type = var.aws_hapee_instance_type

  ami = var.hapee_aws_amis[var.aws_region]

  key_name = var.key_name

  vpc_security_group_ids = [aws_security_group.instance_sg1.id, aws_security_group.instance_sg2.id]
  subnet_id = element(
    aws_subnet.tf_test_subnet.*.id,
    //  count.index / var.hapee_cluster_size,
    count.index,
  )
  user_data = data.template_file.hapee-userdata.rendered

  tags = {
    Name = "hapee_node_${count.index}"
  }
}
