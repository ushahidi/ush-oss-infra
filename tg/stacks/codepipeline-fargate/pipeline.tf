data "aws_s3_bucket" "artifacts" {
  bucket = "zzint-ush-${var.environment}-codepipeline-${var.artifacts_bucket_name}"
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "codepipeline_policy"
  role = "${aws_iam_role.codepipeline.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${data.aws_s3_bucket.artifacts.arn}",
        "${data.aws_s3_bucket.artifacts.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


resource "aws_codepipeline" "main" {
  name     = "${var.environment}-${var.product}-${var.app}-${var.name}"
  role_arn = "${aws_iam_role.codepipeline.arn}"

  artifact_store {
    location = data.aws_s3_bucket.artifacts.bucket
    type = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = merge(
        var.github_repo_config,
        {
          PollForSourceChanges = "false"
        }
      )
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.main.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = data.aws_ecs_cluster.cluster.arn
        ServiceName = aws_ecs_service.main.name
      }
    }
  }
}