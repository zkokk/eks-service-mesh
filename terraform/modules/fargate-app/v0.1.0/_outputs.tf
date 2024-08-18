output "role" {
  value = aws_iam_role.ecs_task
}

output "ecs_service" {
  value = aws_ecs_service.ecs_service
}