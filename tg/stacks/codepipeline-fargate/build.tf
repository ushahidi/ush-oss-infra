data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "codebuild" {
  name = "codebuild_policy"
  role = aws_iam_role.codepipeline.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_codebuild_project" "main" {
  name = "${var.environment}-${var.product}-${var.app}-${var.name}"
  description = "Build for ${var.environment}-${var.product}-${var.app}-${var.name}"
  build_timeout = var.build_timeout
  service_role = aws_iam_role.codepipeline.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/ubuntu/standard:2.0"
    type = "LINUX_CONTAINER"

    environment_variable {
      name = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.main.name
    }

    environment_variable {
      name = "IMAGE_TAG"
      value = "latest"
    }
  }

  tags = {
    ush-environment = var.environment
    ush-product = var.product
    ush-app = var.app
  }
}