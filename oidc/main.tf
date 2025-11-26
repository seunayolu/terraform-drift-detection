# Import existing OIDC provider instead of creating new one
data "aws_iam_openid_connect_provider" "github_oidc_provider" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_oidc_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github_oidc_provider.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.github_repo_conditions
    }
  }
}

# Create the IAM role itself using the trust policy defined above.
resource "aws_iam_role" "github_actions_role" {
  name               = "GitHub-Actions-Terraform-Drift-Role"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json
}

resource "aws_iam_role_policy_attachment" "github_admin_access_attach" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}