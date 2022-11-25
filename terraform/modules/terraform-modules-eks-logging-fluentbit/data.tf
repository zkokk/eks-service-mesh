data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_eks_cluster" "eks_cluster" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "eks_cluster" {
  name = local.cluster_name
}

# Need to be provided from the root module!!!
//provider "kubernetes" {
//  count = var.eks_oidc_issuer_url == null && var.eks_oidc_provider_arn == null ? 1 : 0
//  host                   = element(concat(data.aws_eks_cluster.eks_cluster[*].endpoint, tolist([""])), 0)
//  cluster_ca_certificate = base64decode(element(concat(data.aws_eks_cluster.eks_cluster[*].certificate_authority.0.data, tolist([""])), 0))
//  token                  = element(concat(data.aws_eks_cluster_auth.eks_cluster[*].token, tolist([""])), 0)
//}

data "aws_iam_policy_document" "fluentbit_sa_irsa_log_to_cloudwatch" {

  statement {
    sid = "LogsPushToCloudWatch"

    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "ec2:DescribeVolumes",
      "ec2:DescribeTags"
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "kms_log_to_cloudwatch" {
  for_each = local.log_group_names
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
    ]
    resources = ["*"]
  }

  statement {
    sid = "EcryptDecryptLogsToCloudWatch"
    effect = "Allow"
    principals {
      type       = "Service"
      identifiers = ["logs.${local.region}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:${each.value["log_group_name"]}"]
    }
  }
}

data "aws_iam_policy_document" "fluentbit_sa_irsa_log_to_s3" {
count = local.use_s3_for_logs == "true" ? 1 : 0
  statement {
    sid = "ListObjectsInBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = ["arn:aws:s3:::${local.s3_bucket_configs.s3_bucket_name}"]
  }

  statement {
    sid = "AllObjectActions"
    effect = "Allow"
    actions = ["s3:*Object"]
    resources = ["arn:aws:s3:::${local.s3_bucket_configs.s3_bucket_name}/*"]
  }
}

data "aws_iam_policy_document" "kms_log_to_s3" {
count = local.use_s3_for_logs == "true" && var.existing_s3_bucket_name == null && local.s3_bucket_configs.s3_kms_key_id == null ? 1 : 0
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
    ]
    resources = ["*"]
  }

  statement {
    sid = "EcryptDecryptLogsToS3"
    effect = "Allow"
    principals {
      type       = "AWS"
      #identifiers = [aws_iam_role.fluentbit_sa_irsa.arn]
      identifiers = [format("arn:aws:iam::%s:role/%s-%s", data.aws_caller_identity.current.account_id, var.prefix_name, "sa-role")]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "s3_bucket_policy_enable_tls" {
count = local.use_s3_for_logs == "true" && var.existing_s3_bucket_name == null ? 1 : 0
  statement {
    sid = "AllowTLSRequestsOnly"
    effect = "Deny"
    principals {
      type       = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::${local.s3_bucket_configs.s3_bucket_name}",
      "arn:aws:s3:::${local.s3_bucket_configs.s3_bucket_name}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}