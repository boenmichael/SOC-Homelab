output "soc_private_ip" {
  description = "Private IP address of the SOC (Splunk) VM."
  value       = azurerm_network_interface.splunk_nic.private_ip_address
}

output "ad_private_ip" {
  description = "Private IP address of the AD VM."
  value       = azurerm_network_interface.ad_nic.private_ip_address
}

output "client_private_ip" {
  description = "Private IP address of the client VM."
  value       = azurerm_network_interface.client_nic.private_ip_address
}

output "domain_name" {
  description = "Active Directory domain name configured for the lab."
  value       = var.ad_domain_name
}

output "splunk_url" {
  description = "Splunk Web URL on the private network."
  value       = "https://${azurerm_network_interface.splunk_nic.private_ip_address}:8000"
}

output "management_access_method" {
  description = "Management access path for lab VMs."
  value       = "Azure Bastion Basic"
}
