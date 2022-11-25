# ---------------------------------------------------------------------------------------------------------------------
# Namespace
# ---------------------------------------------------------------------------------------------------------------------
resource "kubernetes_namespace_v1" "amazon_cloudwatch" {
  metadata {
    name   = var.namespace_name
    labels = {
      "name": var.namespace_name
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ConfigMap CloudWatch
# ---------------------------------------------------------------------------------------------------------------------
resource "kubernetes_config_map_v1" "fluentbit_clusterinfo_cm" {
  metadata {
    name      = "${local.prefix_name}-cluster-info"
    namespace = kubernetes_namespace_v1.amazon_cloudwatch.metadata[0].name
  }

  data = {
    for k, v in var.fluentbit_cluster_info_configs : k => v
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Kubernetes FluentBit Service Account
# ---------------------------------------------------------------------------------------------------------------------
resource "kubernetes_service_account_v1" "fluentbit_sa" {
  metadata {
    name        = local.prefix_name
    namespace   = kubernetes_namespace_v1.amazon_cloudwatch.metadata[0].name
    annotations = { "eks.amazonaws.com/role-arn" : aws_iam_role.fluentbit_sa_irsa.arn }
  }
  automount_service_account_token = true
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM / RBAC for FluentBit
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "fluentbit_sa_irsa" {
  name     = format("%s-%s", local.prefix_name, "sa-role")
  #tags     = var.tags
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "${local.eks_oidc_provider_arn}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${local.eks_oidc_issuer_url}:sub" : "system:serviceaccount:${kubernetes_namespace_v1.amazon_cloudwatch.metadata[0].name}:${local.prefix_name}",
            "${local.eks_oidc_issuer_url}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "fluentbit_sa_irsa_cloudwatch_policy" {
  count       = local.use_cloudwatch_for_logs == "true" ? 1 : 0
  name        = local.fluentbit_log_policies.log_to_cloudwatch
  policy      = data.aws_iam_policy_document.fluentbit_sa_irsa_log_to_cloudwatch.json
}

resource "aws_iam_role_policy_attachment" "fluentbit_sa_irsa_cloudwatch_attachment" {
  count      = local.use_cloudwatch_for_logs == "true" ? 1 : 0
  role       = aws_iam_role.fluentbit_sa_irsa.name
  policy_arn = aws_iam_policy.fluentbit_sa_irsa_cloudwatch_policy[0].arn
}

resource "aws_iam_policy" "fluentbit_sa_irsa_s3_policy" {
  count       = local.use_s3_for_logs == "true" ? 1 : 0
  name        = local.fluentbit_log_policies.log_to_s3
  policy      = data.aws_iam_policy_document.fluentbit_sa_irsa_log_to_s3[0].json
}

resource "aws_iam_role_policy_attachment" "fluentbit_sa_irsa_s3_attachment" {
  #for_each = local.fluentbit_log_policies
  count      = local.use_s3_for_logs == "true" ? 1 : 0
  role       = aws_iam_role.fluentbit_sa_irsa.name
  policy_arn = aws_iam_policy.fluentbit_sa_irsa_s3_policy[0].arn
}

resource "kubernetes_cluster_role_v1" "fluentbit_role" {
  metadata {
    name = "${local.prefix_name}-role"
  }

  rule {
    non_resource_urls = ["/metrics"]
    verbs             = ["get"]
  }

  rule {
    api_groups        = [""]
    resources         = ["namespaces", "pods", "pods/logs", "nodes", "nodes/proxy"]
    verbs             = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "fluentbit_rolebinding" {
  metadata {
    name = "${kubernetes_cluster_role_v1.fluentbit_role.metadata[0].name}-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.fluentbit_role.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.fluentbit_sa.metadata[0].name
    namespace = kubernetes_namespace_v1.amazon_cloudwatch.metadata[0].name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# FluentBit KMS for CloudWatch Log Group
# ---------------------------------------------------------------------------------------------------------------------
# Currently FluentBit does not support auto-creation of CloudWatch Groups with KMS key and that is the reason why we create the KMS and Log Groups separately check enhancement ticket https://github.com/aws/amazon-cloudwatch-logs-for-fluent-bit/issues/119.
resource "aws_kms_key" "fluentbit_cloudwatch_kms" {
  for_each = local.log_group_names
  description                          = "Custom KMS keys used by FluentBit to encrypt CloudWatch Log Groups `${each.value["log_group_name"]}`"
  deletion_window_in_days              = each.value["kms_deletion_window_in_days"]
  #tags                                 = local.ami_kms_key_tags
  policy                               = data.aws_iam_policy_document.kms_log_to_cloudwatch[each.key].json
  enable_key_rotation                  = true
}

resource "aws_kms_alias" "fluentbit_cloudwatch_kms_alias" {
  for_each = local.log_group_names
  name                    = "alias/${each.key}"
  target_key_id           = aws_kms_key.fluentbit_cloudwatch_kms[each.key].key_id
}

# ---------------------------------------------------------------------------------------------------------------------
# FluentBit CloudWatch Log Group
# ---------------------------------------------------------------------------------------------------------------------
# Currently FluentBit does not support auto-creation of CloudWatch Groups with KMS key and that is the reason why we create the KMS and Log Groups separately check enhancement ticket https://github.com/aws/amazon-cloudwatch-logs-for-fluent-bit/issues/119.
resource "aws_cloudwatch_log_group" "fluentbit_log_group" {
  for_each = local.log_group_names
  name              = each.value["log_group_name"]
  retention_in_days = each.value["retention_in_days"]
  kms_key_id        = aws_kms_key.fluentbit_cloudwatch_kms[each.key].arn

  #tags = merge(var.tags, var.vpc_flow_log_tags)
}

# ---------------------------------------------------------------------------------------------------------------------
# FluentBit KMS for S3
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_kms_key" "fluentbit_s3_kms" {
  count = local.use_s3_for_logs == "true" && var.existing_s3_bucket_name == null && local.s3_bucket_configs.s3_kms_key_id == null ? 1 : 0
  description                          = "Custom KMS keys used by FluentBit to encrypt logs in S3"
  deletion_window_in_days              = local.s3_bucket_configs.s3_kms_deletion_window_in_days
  #tags                                 = local.ami_kms_key_tags
  policy                               = data.aws_iam_policy_document.kms_log_to_s3[0].json
  enable_key_rotation                  = true
}

resource "aws_kms_alias" "fluentbit_s3_kms_alias" {
  count = local.use_s3_for_logs == "true" && var.existing_s3_bucket_name == null && local.s3_bucket_configs.s3_kms_key_id == null ? 1 : 0
  name                    = "alias/${local.s3_bucket_configs.s3_bucket_name}"
  target_key_id           = aws_kms_key.fluentbit_s3_kms[0].key_id
}

# ---------------------------------------------------------------------------------------------------------------------
# FluentBit S3
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "fluentbit_s3_eks_logs" {
  count = local.use_s3_for_logs == "true" && var.existing_s3_bucket_name == null ? 1 : 0
  #  provider      = aws.databunker
  #depends_on = [aws_s3_bucket.s3_access_logs]
  bucket        = "${local.s3_bucket_configs.s3_bucket_name}"
  force_destroy = "false"
  object_lock_enabled = false

//  logging {
//    target_bucket = "${var.s3_settings.s3_access_log_bucket_name}-${local.current_account_id}"
//    target_prefix = "log/"
//  }
}

resource "aws_s3_bucket_acl" "fluentbit_s3_eks_logs_acl" {
  count = local.use_s3_for_logs == "true" && var.existing_s3_bucket_name == null ? 1 : 0
  bucket = aws_s3_bucket.fluentbit_s3_eks_logs[0].id
  acl    = local.s3_bucket_configs.s3_acl
}

resource "aws_s3_bucket_versioning" "fluentbit_s3_eks_logs_versioning" {
  count = local.use_s3_for_logs == "true" && var.existing_s3_bucket_name == null ? 1 : 0
  bucket = aws_s3_bucket.fluentbit_s3_eks_logs[0].id
  versioning_configuration {
    status = local.s3_bucket_configs.s3_versioning
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "fluentbit_s3_eks_logs_sse" {
  count = local.use_s3_for_logs == "true" && var.existing_s3_bucket_name == null ? 1 : 0
  bucket = aws_s3_bucket.fluentbit_s3_eks_logs[0].bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.s3_bucket_configs.s3_kms_key_id == null ? aws_kms_key.fluentbit_s3_kms[0].arn : local.s3_bucket_configs.s3_kms_key_id
      sse_algorithm     = local.s3_bucket_configs.s3_sse_algorithm
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "fluentbit_s3_eks_logs_lifecycle_conf" {
  count = local.use_s3_for_logs == "true" && var.existing_s3_bucket_name == null ? 1 : 0
  bucket = aws_s3_bucket.fluentbit_s3_eks_logs[0].id

  rule {
    id = "all"

    filter {
      prefix = "/*"
    }

    status = "Enabled"

    transition {
      days          = local.s3_bucket_configs.s3_transition_to_standard_ai_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = local.s3_bucket_configs.s3_transition_to_glacier_ir_days
      storage_class = "GLACIER_IR"
    }

    transition {
      days          = local.s3_bucket_configs.s3_transition_to_glacier_days
      storage_class = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_policy" "fluentbit_s3_eks_logs_policy" {
  count = local.use_s3_for_logs == "true" && var.existing_s3_bucket_name == null ? 1 : 0
  bucket = aws_s3_bucket.fluentbit_s3_eks_logs[0].id
  policy = data.aws_iam_policy_document.s3_bucket_policy_enable_tls[0].json
}

resource "aws_s3_bucket_public_access_block" "fluentbit_s3_eks_logs_public_access_block" {
  count = local.use_s3_for_logs == "true" && var.existing_s3_bucket_name == null ? 1 : 0
  #  provider                = aws.databunker
  bucket                  = aws_s3_bucket.fluentbit_s3_eks_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------------------------------------------------
# ConfigMap FluentBit Log Configs
# ---------------------------------------------------------------------------------------------------------------------
resource "kubernetes_config_map_v1" "fluentbit_cm" {
  metadata {
    name      = "${local.prefix_name}-config"
    namespace = kubernetes_namespace_v1.amazon_cloudwatch.metadata[0].name
    labels = {
      "k8s-app" = local.prefix_name
    }
  }

  data = {
    "application-log.conf" = templatefile("${path.module}/fluentbit_configs/application-log.conf", {
      BUCKET_NAME         = local.s3_bucket_configs.s3_bucket_name
      USE_S3_LOGS         = local.use_s3_for_logs
      USE_CLOUDWATCH_LOGS = local.use_cloudwatch_for_logs
    })
    "dataplane-log.conf" = templatefile("${path.module}/fluentbit_configs/dataplane-log.conf", {
      BUCKET_NAME         = local.s3_bucket_configs.s3_bucket_name
      USE_S3_LOGS         = local.use_s3_for_logs
      USE_CLOUDWATCH_LOGS = local.use_cloudwatch_for_logs
    })
    "fluent-bit.conf" = templatefile("${path.module}/fluentbit_configs/fluent-bit.conf", {})
    "host-log.conf" = templatefile("${path.module}/fluentbit_configs/host-log.conf", {
      BUCKET_NAME         = local.s3_bucket_configs.s3_bucket_name
      USE_S3_LOGS         = local.use_s3_for_logs
      USE_CLOUDWATCH_LOGS = local.use_cloudwatch_for_logs
    })
    "parsers.conf" = templatefile("${path.module}/fluentbit_configs/parsers.conf", {})
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# FluentBit DaemonSet
# ---------------------------------------------------------------------------------------------------------------------
resource "kubernetes_daemon_set_v1" "fluentbit_daemonset" {
  metadata {
    name      = local.prefix_name
    namespace = kubernetes_namespace_v1.amazon_cloudwatch.metadata[0].name
    labels = {
      "k8s-app": local.prefix_name
      "version": "v1"
      "kubernetes.io/cluster-service": "true"
    }
  }

  spec {
    selector {
      match_labels = {
        "k8s-app": local.prefix_name
      }
    }

    template {
      metadata {
        labels = {
          "k8s-app": local.prefix_name
          "version": "v1"
          "kubernetes.io/cluster-service": "true"
        }
      }

      spec {
        container {
          name  = local.prefix_name
          image = var.fluentbit_image
          image_pull_policy = "Always"

          dynamic "env" {
            for_each = local.env_from_configmap
            content {
              name = env.value
              value_from {
                config_map_key_ref {
                  name = kubernetes_config_map_v1.fluentbit_clusterinfo_cm.metadata[0].name
                  key  = env.key
                }
              }
            }
          }

          dynamic "env" {
            for_each = local.env_from_field
            content {
              name = env.value["env_name"]
              value_from {
                field_ref {
                  field_path = env.value["env_value"]
                }
              }
            }
          }

          env {
            name  = "CI_VERSION"
            value = "k8s/1.3.10"
          }

          resources {
            limits = {
              cpu    = "1000m"
              memory = "200Mi"
            }
            requests = {
              cpu    = "500m"
              memory = "100Mi"
            }
          }

          dynamic "volume_mount" {
            for_each = local.volume_mounts
            content {
              mount_path = volume_mount.value["mount_path"]
              sub_path   = try(volume_mount.value["sub_path"], null)
              name       = volume_mount.key
              read_only  = try(volume_mount.value["read_only"], "false")
            }
          }
        }

        termination_grace_period_seconds = "10"
        host_network                     = "true"
        dns_policy                       = "ClusterFirstWithHostNet"
        service_account_name             = kubernetes_service_account_v1.fluentbit_sa.metadata[0].name

        dynamic "volume" {
          for_each = local.volumes.hostPathVolumes
          content {
            host_path {
              path = volume.value["mount_path"]
              type = try(volume.value["type"], null)
            }
            name = volume.key
          }
        }

        dynamic "volume" {
          for_each = local.volumes.configMapVolumes
          content {
            config_map {
              default_mode = try(volume.value["default_mode"], null)
              name         = volume.key
            }
            name = volume.key
          }
        }

        dynamic "toleration" {
          for_each = local.tolerations
          content {
            effect             = try(toleration.value["effect"], null)
            key                = try(toleration.value["key"], null)
            operator           = try(toleration.value["operator"], null)
            toleration_seconds = try(toleration.value["toleration_seconds"], null)
            value              = try(toleration.value["value"], null)
          }
        }
      }
    }
  }
}