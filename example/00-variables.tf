
# Terraform provisioning role by env
variable "provisioning_role" {
  type = string
}

variable "state_bueckt_region" {
  type = string
}

variable "state_bueckt_name" {
  type = string
}

variable "state_file_name" {
  type = string
}

variable "state_bucket_assume_role_arn" {
  type = string
}

variable "state_bucket_assume_role_session_name" {
  type = string
}