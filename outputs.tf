output "vm_public_ips" {
  description = "Public IPs of all nodes"
  value = merge(
    { for k, v in azurerm_public_ip.pip_a : k => v.ip_address },
    { for k, v in azurerm_public_ip.pip_b : k => v.ip_address }
  )
}

output "vm_private_ips" {
  description = "Private IPs of all nodes"
  value = merge(
    { for k, v in azurerm_network_interface.nic_a : k => v.private_ip_address },
    { for k, v in azurerm_network_interface.nic_b : k => v.private_ip_address }
  )
}

output "control_plane_private_ip" {
  description = "Private IP of the control plane node"
  value       = azurerm_network_interface.nic_a["vm0"].private_ip_address
}