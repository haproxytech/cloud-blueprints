output "aws_availability_zones_in_use" {
  description = "AWS availability zones in use"
  value       = aws_subnet.tf_test_subnet.*.availability_zone
}

output "hapee_nodes" {
  description = "HAPEE nodes"
  value = formatlist(
    "%s, private IP: %s, public IP: %s, AZ: %s",
    aws_instance.hapee_node.*.id,
    aws_instance.hapee_node.*.private_ip,
    aws_instance.hapee_node.*.public_ip,
    aws_instance.hapee_node.*.availability_zone,
  )
}

output "web_node_private_ips" {
  description = "Web node private IPs"
  value = formatlist(
    "%s, private IP: %s, public IP: %s, AZ: %s",
    aws_instance.web_node.*.id,
    aws_instance.web_node.*.private_ip,
    aws_instance.web_node.*.public_ip,
    aws_instance.web_node.*.availability_zone,
  )
}

output "alb_dns_address" {
  description = "ALB DNS address"
  value       = aws_lb.hapee_alb.dns_name
}

output "alb_target_group" {
  description = "ALB target group"
  value       = aws_instance.hapee_node.*.id
}

output "hapee_backend_server_list" {
  description = "HAPEE backend server list"
  value = join(
    "\n",
    formatlist(
      "    server app-%v %v:80 cookie app-%v check",
      aws_instance.web_node.*.id,
      aws_instance.web_node.*.private_ip,
      aws_instance.web_node.*.id,
    ),
  )
}
