##################################################
# Terraform CLI를 실행시킬 AWS Codebuild 입니다.

resource "aws_codebuild_project" "codebuild" {
  name         = "build-${local.name_tag_middle}-terraform"
  description  = "Run terraform CLI"
  service_role = aws_iam_role.codebuild.arn

  # Source
  source {
    # 어차피 AWS Pipeline으로 Source가 입력되므로 지정할 Source를 지정할 필요는 없습니다.
    type      = "NO_SOURCE"
    buildspec = templatefile("${path.module}/buildspec.tpl", {})
  }

  # Artifacts
  artifacts {
    type                = "S3"
    location            = aws_s3_bucket.artifact_bucket.id
    path                = "BuildAlone"
    packaging           = "NONE"
    namespace_type      = "BUILD_ID"
    encryption_disabled = true
  }

  # Docker runtime
  environment {
    type  = "LINUX_CONTAINER"
    image = data.aws_ecr_repository.this.repository_url
    # image_pull_credentials_type = "CODEBUILD" # SERVICE_ROLE
    image_pull_credentials_type = "SERVICE_ROLE" # 
    compute_type                = "BUILD_GENERAL1_SMALL"
  }

  # Cache
  cache {
    type  = "LOCAL"
    modes = ["LOCAL_CUSTOM_CACHE"]
  }

  # Bulid log
  logs_config {
    cloudwatch_logs {
      group_name = "/terraform/pipe-${local.name_tag_middle}-build"
    }
  }

  tags = merge(
    var.global_additional_tag, {
      Name = "build-${local.name_tag_middle}-terraform"
  })
}
##################################################


##################################################
# 실행결과를 저장할 Cloud watch 입니다.
resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/terraform/pipe-${local.name_tag_middle}-build"
  retention_in_days = 1
  tags = merge(
    var.global_additional_tag, {
      Name = "cw-${local.name_tag_middle}-build"
  })
}
##################################################


##################################################
# AWS Codebuild의 Service Role 입니다.

resource "aws_iam_role" "codebuild" {
  name               = "role-${local.name_tag_middle}-build-terraform"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

# IAM Policy
resource "aws_iam_policy" "codebuild" {
  name   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild_policy.json
}

# IAM policy attachment
resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild.arn
}

# Assume role
data "aws_iam_policy_document" "codebuild_assume" {
  # Allow Codebuild service to assume this role
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "codebuild.amazonaws.com"
      ]
    }
  }
}

# Policy
data "aws_iam_policy_document" "codebuild_policy" {
  # Allow logging to Cloudwatch
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.codebuild.arn,
      "${aws_cloudwatch_log_group.codebuild.arn}:*",
    ]
  }

  # Allow storing artifacts to S3 bucket
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetBucketAcl",
      "s3:GetObjectVersion",
      "s3:GetBucketLocation",
    ]
    resources = [
      aws_s3_bucket.artifact_bucket.arn,
      "${aws_s3_bucket.artifact_bucket.arn}/*",
    ]
  }

  # Allow pulling source code from CodeCommit
  # statement {
  #   effect = "Allow"
  #   actions = [
  #     "codecommit:GitPull",
  #   ]
  #   resources = [
  #     "arn:aws:codecommit:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:*"
  #   ]
  # }

  # Allow loading docker image from ECR private repository
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = [
      # data.aws_ecr_repository.this.arn,
      "*"
    ]
  }

  # Allow assume role
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      "*"
    ]
  }
}
##################################################