output "codebuild_serivce_role_arn" {
  value = aws_iam_role.codebuild.arn
}

output "remote_state_bueckt_arn" {
  value = var.remote_state_bucket.create_bucket ? aws_s3_bucket.state_bucket["this"].arn : var.remote_state_bucket.bucket_arn
}

output "remote_state_assume_role_arn" {
  value = var.remote_state_bucket.create_assume_role ? aws_iam_role.state_file_bucket["this"].arn : var.remote_state_bucket.assume_role_arn
}