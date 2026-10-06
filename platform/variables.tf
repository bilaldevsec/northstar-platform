variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID"
}

variable "admin_ip_cidr" {
  type        = string
  description = "The admin IP CIDR for administrative access"
}

variable "location" {
  type        = string
  description = "The Azure region"
  default     = "eastus"
}

variable "env" {
  type        = string
  description = "The environment environment"
  default     = "dev"
}
