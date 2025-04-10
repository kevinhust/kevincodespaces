output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.asg.name
}

output "launch_configuration_name" {
  description = "Name of the Launch Configuration"
  value       = aws_launch_configuration.launch_config.name
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.web_role.name
} 