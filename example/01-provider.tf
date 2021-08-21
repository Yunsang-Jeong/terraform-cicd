provider "aws" {
  region = "ap-northeast-2"

  assume_role {
    role_arn = var.provisioning_role
  }
}