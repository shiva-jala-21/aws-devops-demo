output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.python_app.repository_url
}

output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.app.dns_name
}