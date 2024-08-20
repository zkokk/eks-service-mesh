resource "aws_cloudwatch_log_group" "app" {
  name              = local.cw_loggroup_name
  retention_in_days = var.aws_logs_retention_in_days
}
