# outputs.tf
# Values displayed after terraform apply

output "defectdojo_url" {
  description = "URL to access DefectDojo"
  value       = "http://${azurerm_public_ip.devsecops.ip_address}:8080"
}

output "vm_public_ip" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.devsecops.ip_address
}

output "ssh_command" {
  description = "Command to SSH into the VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.devsecops.ip_address}"
}
