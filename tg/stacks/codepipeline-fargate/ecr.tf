resource "aws_iam_role_policy" "registry" {
  name = "registry_policy"
  role = aws_iam_role.codepipeline.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "${aws_ecr_repository.main.arn}"
      ],
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:Describe*",
        "ecr:Get*",
        "ecr:InitiateLayerUpload",
        "ecr:List*",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ]
    }
  ]
}
EOF
}

resource "aws_ecr_repository" "main" {
  name = "${var.environment}-${var.product}-${var.app}-${var.name}"

  tags = {
    ush-environment = "${var.environment}"
    ush-product = "${var.product}"
  }
}

resource "aws_ecr_lifecycle_policy" "keep_last" {
  repository = aws_ecr_repository.main.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last ${var.keep_n_last_images} images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": ${var.keep_n_last_images}
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}
