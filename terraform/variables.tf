variable "region" {
  type        = string
  description = "The AWS Region where regional resources will be deployed"
  nullable    = false
}

variable "vpc_cidr" {
  type        = string
  description = "The VPC cidr block"
  nullable    = false
  validation {
    condition     = can(cidrsubnet(var.vpc_cidr, 8, 0))
    error_message = "vpc_cidr must be valid CIDR BLOCK"
  }
}

variable "instance_type" {
  type        = string
  description = "The type of EC2 instance"
  nullable    = false
}

variable "public_key_file" {
  type        = string
  description = "The file that contain the RSA SSH public key"
  nullable    = false
  default     = "~/.ssh/id_rsa.pub"
}
