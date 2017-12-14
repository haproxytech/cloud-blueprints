output "AWS availability zones in use" {
  value = "${aws_subnet.tf_test_subnet.*.availability_zone}"
}

output "HAPEE nodes" {
  value = "${formatlist("%s, private IP: %s, public IP: %s, AZ: %s", aws_instance.hapee_node.*.id, aws_instance.hapee_node.*.private_ip, aws_instance.hapee_node.*.public_ip, aws_instance.hapee_node.*.availability_zone)}"
}

output "Web node private IPs" {
  value = "${formatlist("%s, private IP: %s, public IP: %s, AZ: %s", aws_instance.web_node.*.id, aws_instance.web_node.*.private_ip, aws_instance.web_node.*.public_ip, aws_instance.web_node.*.availability_zone)}"
}

output "ALB DNS address" {
  value = "${aws_lb.hapee_alb.dns_name}"
}

output "ALB target group" {
  value = "${aws_instance.hapee_node.*.id}"
}

output "HAPEE backend server list" {
  value = "${join("\n", formatlist("    server app-%v %v:80 cookie app-%v check", aws_instance.web_node.*.id, aws_instance.web_node.*.private_ip, aws_instance.web_node.*.id))}"
}
