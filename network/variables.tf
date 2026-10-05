variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "southeastasia"
}

variable "admin_ip_cidr" {
  description = "Admin IP CIDR for allowed access"
  type        = string
}

variable "enable_firewall" {
  description = "Enable Azure Firewall"
  type        = bool
  default     = false
}
