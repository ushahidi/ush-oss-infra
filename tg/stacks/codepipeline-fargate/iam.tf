# role used by codepipeline and codebuild
resource "aws_iam_role" "codepipeline" {
  name = "${var.environment}-${var.product}-${var.app}-${var.name}-codepipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codepipeline.amazonaws.com",
          "codebuild.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
