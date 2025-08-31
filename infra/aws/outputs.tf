output "public_ip" {
  description = "The public IP address of the web server"
  value       = aws_instance.assetrix_app.public_ip
}