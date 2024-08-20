variable "fluentbit_cluster_info_configs" {
  description = "FluentBit major configuration settings"
  type        = map(string)
  default = {
    "logs.region"  = "eu-west-1",
    "cluster.name" = "swo-onboarding",
    "http.server"  = "On",
    "http.port"    = "2020",
    "read.head"    = "Off",
    "read.tail"    = "On"
  }
}

variable "fluentbit_image" {
  description = "FluentBit image which will be used for the DaemonSet deployment"
  type        = string
  default     = "public.ecr.aws/aws-observability/aws-for-fluent-bit:stable"
}

variable "namespace_name" {
  description = "Name of the namespace where the fluent-bit will be deployed"
  type        = string
  default     = "amazon-cloudwatch"
}

variable "logs_destination_store" {
  description = "Destination where the EKS application/dataplane/host logs will be forwarded by FluentBit. Possible options are `cloudwatch`, `s3` or `both` of them. Default is `both`"
  type        = string
  default     = "both"
}

variable "s3_kms_key_id" {
  description = "Key ID of the KMS key which was created for S3 bucket"
  type        = string
  default     = null
}

variable "existing_s3_bucket_name" {
  description = "Name of an existing S3 Bucket which will be used. If you use this S3 bucket must be created out side of this code and all the security consideration must be in place (for example encryption and so on). If this variable is not specified current code will create S3, KMS keys for them and will add the needed permissions"
  type        = string
  default     = null
}

variable "prefix_name" {
  description = "Prefix Name which will be used resource creation"
  type        = string
  default     = null
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
  default     = null
}

variable "eks_oidc_issuer_url" {
  description = ""
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = ""
  type        = string
}