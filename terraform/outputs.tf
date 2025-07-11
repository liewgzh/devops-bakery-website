output "control_node_public_ip" {
  value = aws_instance.control_node.public_ip
}

# output "managed_node_1_private_ip" {
#   value = aws_instance.managed_node_1.private_ip
# }

output "managed_node_2_private_ip" {
  value = aws_instance.managed_node_2.private_ip
}

output "node2_public_ip" {
  value = aws_instance.managed_node_2.public_ip
}

