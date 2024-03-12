variable "environment" {
  type        = string
  description = "Name of the environment"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR block"
}

variable "public_subnets" {
  type    = list(string)
  description = "Public subnets for vpc"
}

variable "private_subnets" {
  type    = list(string)
  description = "Public subnets for vpc"
}

variable "region" {
  type        = string
  description = "Name of the region where the environment will be running"
}

variable "eks_version" {
  type        = number
  description = "EKS version"
  default     = null
}

variable "workernodes_instance_type" {
  type        = string
  description = "The type of instance for the worker nodes"
}

variable "workernodes_disk_size" {
  type        = number
  description = "The disk size for each worker node"
  default     = null
}

variable "ebs_csi_addon_version" {
  type        = string
  description = "The version for EBS CSI Add-on for EKS"
}