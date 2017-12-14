output "HAPEE nodes private IPs" {
  value = "${aws_instance.hapee_node.*.private_ip}"
}

output "HAPEE node public IPs" {
  value = "${aws_instance.hapee_node.*.public_ip}"
}

output "Web node private IPs" {
  value = "${aws_instance.web_node.*.private_ip}"
}

output "Web node public IPs" {
  value = "${aws_instance.web_node.*.public_ip}"
}

output "ELB DNS address" {
  value = "${aws_elb.hapee_elb.dns_name}"
}
