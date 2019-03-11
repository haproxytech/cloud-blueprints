output "HAPEE nodes private IPs" {
  value = "${aws_instance.hapee_node.*.private_ip}"
}

output "HAPEE node EIP1 (primary interface) allocation IDs" {
  value = "${aws_eip.hapee_node_eip1.*.id}"
}

output "HAPEE node EIP1 (primary interface) public IPs" {
  value = "${aws_eip.hapee_node_eip1.*.public_ip}"
}

output "HAPEE node primary interface IDs" {
  value = "${aws_instance.hapee_node.*.primary_network_interface_id}"
}

output "Web node private IPs" {
  value = "${aws_instance.web_node.*.private_ip}"
}

output "Web node public IPs" {
  value = "${aws_instance.web_node.*.public_ip}"
}
