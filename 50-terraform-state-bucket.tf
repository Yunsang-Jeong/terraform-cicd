##################################################
# State를 저장할 S3 버킷입니다.

resource "aws_s3_bucket" "state_bucket" {
  for_each = var.remote_state_bucket.create_bucket ? { this : "" } : {}

  bucket        = "bucket-${local.name_tag_middle}-terraform-state"
  acl           = "private"
  force_destroy = true
  tags = merge(
    var.global_additional_tag, {
      Name = "bucket-${local.name_tag_middle}-terraform-state"
  })
}

resource "aws_s3_bucket_public_access_block" "state_bucket" {
  for_each = var.remote_state_bucket.create_bucket ? { this : "" } : {}
  
  bucket = aws_s3_bucket.state_bucket["this"].id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}
##################################################


##################################################
# State를 사용할 수 있는 IAM Role을 생성합니다.

resource "aws_iam_role" "state_file_bucket" {
  for_each = var.remote_state_bucket.create_assume_role ? { this : "" } : {}

  name               = "role-${local.name_tag_middle}-build-terraform-state"
  assume_role_policy = data.aws_iam_policy_document.state_file_bucket_assume["this"].json
}

# AWS Codebuild의 Service role에서 사용할 수 있도록 신뢰관계를 설정합니다.
data "aws_iam_policy_document" "state_file_bucket_assume" {
  for_each = var.remote_state_bucket.create_assume_role ? { this : "" } : {}

  
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.codebuild.arn 
        # "arn:aws:iam::${data.aws_caller_identity.this.accont_id}:role/role-${local.name_tag_middle}-build-terraform"
      ]
    }
  }
  depends_on = [aws_iam_role.codebuild]
}
##################################################


##################################################
# State를 사용할 수 있는 IAM Role에 권한을 추가합니다.

resource "aws_iam_policy" "state_file_bucket" {
  for_each = var.remote_state_bucket.create_assume_role ? { this : "" } : {}

  name   = aws_iam_role.state_file_bucket["this"].name
  policy = data.aws_iam_policy_document.state_file_bucket_policy["this"].json
}

resource "aws_iam_role_policy_attachment" "state_file_bucket" {
  for_each = var.remote_state_bucket.create_assume_role ? { this : "" } : {}

  role       = aws_iam_role.state_file_bucket["this"].name
  policy_arn = aws_iam_policy.state_file_bucket["this"].arn
}

data "aws_iam_policy_document" "state_file_bucket_policy" {
  for_each = var.remote_state_bucket.create_assume_role ? { this : "" } : {}

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      var.remote_state_bucket.create_bucket ? "${aws_s3_bucket.state_bucket["this"].arn}/*" : "${var.remote_state_bucket.assume_role_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      var.remote_state_bucket.create_bucket ? aws_s3_bucket.state_bucket["this"].arn : var.remote_state_bucket.assume_role_arn
    ]
  }
}
##################################################