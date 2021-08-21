##################################################
# Shared
variable "name_tag_convention" {
  description = "Name tag convention"
  type = object({
    project_name = string
    stage        = string
  })
  default = {
    project_name = ""
    stage        = ""
  }
}

variable "additional_tag" {
  description = "Additional tags for all resources created within a Terraform, e.g. Enviroment, System"
  type        = map(string)
  default     = {}
}
##################################################


##################################################
# Terraform remote state
variable "remote_state_bucket" {
  type = object({
    create_bucket      = bool
    create_assume_role = bool
    bucket_arn         = optional(string)
    assume_role_arn    = optional(string)
  })
}
##################################################


##################################################
# Codebuild
variable "codebuild_ecr_name" {
  description = "Docker image for build"
  type        = string
}
##################################################


##################################################
# Codepipeline
variable "codepipeline_stages" {
  description = "Bracnh name"
  type        = list(string)
  default     = ["dev", "prd"]
}
##################################################