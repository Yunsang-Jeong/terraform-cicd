##################################################
# AWS CodeBuild 실행결과로 생성되는 Artifact를 저장할 S3 버킷입니다.

resource "aws_s3_bucket" "artifact_bucket" {
  bucket        = "bucket-${local.name_tag_middle}-terraform-artifact"
  acl           = "private"
  force_destroy = true
  tags = merge(
    var.global_additional_tag, {
      Name = "bucket-${local.name_tag_middle}-terraform-artifact"
  })
}

resource "aws_s3_bucket_public_access_block" "artifact_bucket" {
  bucket = aws_s3_bucket.artifact_bucket.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}
##################################################