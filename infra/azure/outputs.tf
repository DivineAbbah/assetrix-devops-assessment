output "public_ip_address" {
  description = "The public IP address of the Azure VM"
  value       = azurerm_public_ip.assetrix_pip.ip_address
}