output "cm_data" {
  value = kubernetes_config_map_v1.fluentbit_clusterinfo_cm.data
}

output "env_from_configmap" {
  value = local.env_from_configmap
}

output "volume_mounts" {
  value = local.volume_mounts
}

output "fluentbit_config_files" {
  value = local.fluentbit_config_files
}

output "fluentbit_configmap_configs" {
  value = local.fluentbit_configmap_configs
}

//output "kms_module" {
//  value = module.fluentbit_cloudwatch_kms
//}

output "kms_policy" {
  value = { for k, v in data.aws_iam_policy_document.kms_log_to_cloudwatch : k => v.json }
}

output "log_groups" {
  value = aws_cloudwatch_log_group.fluentbit_log_group
}