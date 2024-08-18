locals {
  partition  = data.aws_partition.current.partition
  region     = var.fluentbit_cluster_info_configs["logs.region"] == null ? data.aws_region.current.name : var.fluentbit_cluster_info_configs["logs.region"]
  account_id = var.account_id == null ? data.aws_caller_identity.current.account_id : var.account_id
  //  eks_oidc_issuer_url   = replace(data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")
  //  eks_oidc_provider_arn = "arn:${local.partition}:iam::${local.account_id}:oidc-provider/${local.eks_oidc_issuer_url}"
  eks_oidc_issuer_url   = var.eks_oidc_issuer_url
  eks_oidc_provider_arn = var.eks_oidc_provider_arn
  prefix_name           = var.prefix_name == null ? "fluent-bit" : var.prefix_name
  cluster_name          = var.fluentbit_cluster_info_configs["cluster.name"] == null ? "swo-onboarding" : 0

  fluentbit_image        = var.fluentbit_image == null ? "public.ecr.aws/aws-observability/aws-for-fluent-bit:stable" : var.fluentbit_image
  fluentbit_config_files = fileset(path.module, "fluentbit_configs/*")
  fluentbit_configmap_configs = { for v in local.fluentbit_config_files :
    [for i in split("/", v) : format("%s", i)][1] => v
  }

  env_from_configmap = { for k, v in kubernetes_config_map_v1.fluentbit_clusterinfo_cm.data :
    k => join("_", [for i in split(".", replace(k, "/^read/", "READ_FROM")) : replace(upper(i), "/^LOGS/", "AWS")])
  }

  env_from_field = {
    nodeName = {
      "env_name"  = "HOST_NAME",
      "env_value" = "spec.nodeName"
    }
    hostName = {
      "env_name"  = "HOSTNAME",
      "env_value" = "metadata.name"
    }
  }

  volume_mounts = merge(local.volumes.hostPathVolumes, local.volumes.configMapVolumes)
  volumes = {
    hostPathVolumes = {
      fluentbitstate = {
        mount_path = "/var/fluent-bit/state"
      },
      varlog = {
        mount_path = "/var/log"
        read_only  = "true"
      },
      varlibdockercontainers = {
        mount_path = "/var/lib/docker/containers"
        read_only  = "true"
      },
      runlogjournal = {
        mount_path = "/run/log/journal"
        read_only  = "true"
      },
      dmesg = {
        mount_path = "/var/log/dmesg"
        read_only  = "true"
      }
    }
    configMapVolumes = {
      fluent-bit-config = {
        mount_path = "/fluent-bit/etc/"
      }
    }
  }

  tolerations = {
    condition_1 = {
      key      = "node-role.kubernetes.io/master"
      operator = "Exists"
      effect   = "NoSchedule"
    },
    condition_2 = {
      operator = "Exists"
      effect   = "NoSchedule"
    },
    condition_3 = {
      operator = "Exists"
      effect   = "NoSchedule"
    }
  }

  log_group_names = var.logs_destination_store == "cloudwatch" || var.logs_destination_store == "both" ? {
#    application = {
#      "log_group_name"              = "/aws/eks/containerinsights/${local.cluster_name}/application"
#      "retention_in_days"           = "30"
#      "kms_deletion_window_in_days" = "7"
#    },
    dataplane = {
      "log_group_name"              = "/aws/eks/containerinsights/${local.cluster_name}/dataplane"
      "retention_in_days"           = "30"
      "kms_deletion_window_in_days" = "7"
    },
    host = {
      "log_group_name"              = "/aws/eks/containerinsights/${local.cluster_name}/host"
      "retention_in_days"           = "30"
      "kms_deletion_window_in_days" = "7"
    }
  } : {}

  fluentbit_log_policies = {
    log_to_cloudwatch = "LogsPushedToCloudWatchPolicy"
    log_to_s3         = "LogsPushedToS3Policy"
  }

  s3_bucket_configs = {
    s3_bucket_name                    = var.existing_s3_bucket_name == null ? "${local.cluster_name}-${local.prefix_name}-logs-bucket-${local.account_id}" : var.existing_s3_bucket_name
    s3_versioning                     = "Enabled"
    s3_kms_deletion_window_in_days    = "30"
    s3_kms_key_id                     = var.s3_kms_key_id == null ? null : var.s3_kms_key_id
    s3_acl                            = "private"
    s3_sse_algorithm                  = "aws:kms"
    s3_transition_to_standard_ai_days = 90
    s3_transition_to_glacier_ir_days  = 365
    s3_transition_to_glacier_days     = 1095
  }
  use_cloudwatch_for_logs = var.logs_destination_store == "cloudwatch" || var.logs_destination_store == "both" ? "true" : "false"
  use_s3_for_logs         = var.logs_destination_store == "s3" || var.logs_destination_store == "both" ? "true" : "false"
}