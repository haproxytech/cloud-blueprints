output "hapee_nodes_private_ips" {
  description = "HAPEE nodes private IPs"
  value       = aws_instance.hapee_node.*.private_ip
}

output "hapee_node_eip1_allocation_ids" {
  description = "HAPEE node EIP1 (primary interface) allocation IDs"
  value       = aws_eip.hapee_node_eip1.*.id
}

output "hapee_node_eip1_public_ips" {
  description = "HAPEE node EIP1 (primary interface) public IPs"
  value       = aws_eip.hapee_node_eip1.*.public_ip
}

output "hapee_node_primary_interface_ids" {
  description = "HAPEE node primary interface IDs"
  value       = aws_instance.hapee_node.*.primary_network_interface_id
}

output "web_node_private_ips" {
  description = "Web node private IPs"
  value       = aws_instance.web_node.*.private_ip
}

output "web_node_public_ips" {
  description = "Web node public IPs"
  value       = aws_instance.web_node.*.public_ip
}
