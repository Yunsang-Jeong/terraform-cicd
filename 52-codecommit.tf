##################################################
# Terraform 코드를 저장할 AWS Codecommit 저장소입니다.

resource "aws_codecommit_repository" "codecommit" {
  repository_name = "tf-service-${local.project_name}"
  description     = "terraform configuration repository"
  default_branch  = "main"
  tags = merge(
    var.global_additional_tag, {
      Name = "tf-service-${local.project_name}"
  })
}
##################################################