#ECS task execution role is capabilities of ECS agent (and container instance), e.g:
# - Pulling a container image from Amazon ECR
# - Using the awslogs log driver
#
#ECS task role is specific capabilities within the task itself, e.g:
# - When your actual code runs


resource "aws_iam_role" "ecs_task" {
  assume_role_policy = file("${path.module}/policies/ecs-task_assume_role_policy.json")

  name = "${local.app_name}-iam-task-role"
}

resource "aws_iam_policy" "ecs_task" {
  name        = "${local.app_name}-iam-policy"
  description = "IAM Policy for ECS task role - ${local.app_name}"
  policy      = var.iam_policy_task_role
}

resource "aws_iam_role_policy_attachment" "ecs_task" {
  policy_arn = aws_iam_policy.ecs_task.arn
  role       = aws_iam_role.ecs_task.name
}

resource "aws_iam_role" "ecs_task_execution" {
  assume_role_policy = file("${path.module}/policies/ecs-task_assume_role_policy.json")

  name = "${local.app_name}-iam-execution-role"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_execution.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_cw_logs" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  role       = aws_iam_role.ecs_task_execution.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_s3_read" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.ecs_task_execution.name
}

resource "aws_iam_policy" "task_exec_custom" {
  name   = "${local.app_name}-CustomPolicy"
  policy = var.iam_policy_execution_role
}

resource "aws_iam_role_policy_attachment" "custom" {
  policy_arn = aws_iam_policy.task_exec_custom.arn
  role       = aws_iam_role.ecs_task_execution.name
}