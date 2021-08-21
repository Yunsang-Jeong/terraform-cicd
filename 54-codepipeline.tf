##################################################
# Terraform CICD를 위한 AWS Codepipeline 입니다.

resource "aws_codepipeline" "this" {
  for_each = { for stage in var.codepipeline_stages : stage => "" }

  name     = "pipe-${local.name_tag_middle}-terraform-${each.key}"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.artifact_bucket.id
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      run_order        = 1
      output_artifacts = ["TerraformConfiguration"]

      configuration = {
        RepositoryName       = element(split(":", aws_codecommit_repository.codecommit.arn), 5)
        BranchName           = each.key
        PollForSourceChanges = "false"
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Terraform-Plan"
    action {
      name             = "Plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      run_order        = 1
      input_artifacts  = ["TerraformConfiguration"]
      output_artifacts = ["TerraformPlan"]
      configuration = {
        ProjectName   = aws_codebuild_project.codebuild.name
        PrimarySource = "TerraformConfiguration"
        EnvironmentVariables = jsonencode([{
          name  = "BUILDSTEP",
          type  = "PLAINTEXT",
          value = "planner"
          }, {
          name  = "WORKSPACE",
          type  = "PLAINTEXT",
          value = each.key
        }])
      }
    }
  }

  stage {
    name = "Approval"
    action {
      name      = "TerraformPlanApproval"
      category  = "Approval"
      owner     = "AWS"
      provider  = "Manual"
      version   = "1"
      run_order = 1

      configuration = {
        CustomData = "Do you approve the plan?"
      }
    }
  }

  stage {
    name = "Terraform-Apply-or-Destroy"
    action {
      name            = "Apply"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      run_order       = 1
      input_artifacts = ["TerraformConfiguration", "TerraformPlan"]
      configuration = {
        ProjectName   = aws_codebuild_project.codebuild.name
        PrimarySource = "TerraformConfiguration"
        EnvironmentVariables = jsonencode([{
          name  = "BUILDSTEP",
          type  = "PLAINTEXT",
          value = "runner"
          }, {
          name  = "WORKSPACE",
          type  = "PLAINTEXT",
          value = each.key
        }])
      }
    }
  }

  tags = merge(
    var.global_additional_tag, {
      Name = "pipe-${local.name_tag_middle}-terraform-${each.key}"
  })
}
##################################################


##################################################
# IAM Role
resource "aws_iam_role" "codepipeline" {
  name               = "role-${local.name_tag_middle}-build-terraform-pipeline"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json
}

# IAM Policy
resource "aws_iam_policy" "codepipeline" {
  name   = aws_iam_role.codepipeline.name
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

# IAM Policy Attachment
resource "aws_iam_role_policy_attachment" "codepipeline" {
  role       = aws_iam_role.codepipeline.name
  policy_arn = aws_iam_policy.codepipeline.arn
}

# Assume 
data "aws_iam_policy_document" "codepipeline_assume" {
  # Allow Codepipeline service to assume this role
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "codepipeline.amazonaws.com",
      ]
    }
  }
}

# Policy 
data "aws_iam_policy_document" "codepipeline_policy" {
  # Allow storing artifacts to S3 bucket
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
    ]
    resources = [
      aws_s3_bucket.artifact_bucket.arn,
      "${aws_s3_bucket.artifact_bucket.arn}/*",
    ]
  }

  statement {
    # Allow pulling source code from CodeCommit
    effect = "Allow"
    actions = [
      # "codecommit:GitPull",
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:UploadArchive",
      "codecommit:GetUploadArchiveStatus"
    ]
    resources = [
      aws_codecommit_repository.codecommit.arn
    ]
  }

  # Allow Starting build
  statement {
    effect = "Allow"
    actions = [
      "codebuild:StartBuild",
      "codebuild:BatchGetBuilds"
    ]
    resources = [
      aws_codebuild_project.codebuild.arn
    ]
  }

  # Allow loading docker image from ECR private repository
  statement {
    effect = "Allow"
    actions = [
      "ecr:DescribeImages"
    ]
    resources = [
      data.aws_ecr_repository.this.arn
    ]
  }
}
##################################################