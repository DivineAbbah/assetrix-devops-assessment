variable "location" {
  description = "The Azure Region to deploy to"
  default     = "East US"
}

variable "admin_username" {
  description = "Admin username for the VM"
  default     = "azureuser"
}

variable "dockerhub_username" {
  description = "Username for Docker Hub authentication"
  type        = string
  sensitive   = true
}

variable "dockerhub_token" {
  description = "Access token for Docker Hub authentication"
  type        = string
  sensitive   = true
}

variable "docker_image" {
  description = "Name of the Docker image to deploy"
  type        = string
}

variable "image_tag" {
  description = "Tag of the Docker image to deploy"
  type        = string
}
