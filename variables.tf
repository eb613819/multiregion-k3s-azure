variable "region_a" {
  description = "Primary region (hosts control plane)"
  type        = string
}

variable "region_b" {
  description = "Secondary region (worker nodes only)"
  type        = string
}

variable "prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "admin_username" {
  description = "Admin username for all VMs"
  type        = string
}

variable "ssh_pub_key" {
  description = "Path to your SSH public key"
  type        = string
}

variable "vm_size" {
  description = "VM size for all nodes"
  type        = string
}

variable "image" {
  description = "OS image for all VMs"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}