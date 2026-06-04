# variables.tf
# All configurable values for the DefectDojo deployment

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "devsecops-lab-rg"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "Denmark East"  # Frankfurt is closest
}

variable "vm_size" {
  description = "Azure VM size - Standard_B1s is free tier eligible"
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "allowed_ip" {
  description = "Your IP address to restrict SSH and DefectDojo access"
  type        = string
  default     = "*"  # ⚠️ Change this to your IP for production!
}
