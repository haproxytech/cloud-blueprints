output "hapee_node_private_ips" {
  description = "HAPEE nodes private IPs"
  value       = aws_instance.hapee_node.*.private_ip
}

output "hapee_node_public_ips" {
  description = "HAPEE nodes public IPs"
  value       = aws_instance.hapee_node.*.public_ip
}

output "web_node_private_ips" {
  description = "Web node private IPs"
  value       = aws_instance.web_node.*.private_ip
}

output "web_node_public_ips" {
  description = "Web node public IPs"
  value       = aws_instance.web_node.*.public_ip
}

output "elb_dns_address" {
  description = "ELB DNS address"
  value       = aws_elb.hapee_elb.dns_name
}
