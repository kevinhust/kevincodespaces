output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.launch_template.id
}

output "launch_template_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.launch_template.latest_version
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.asg.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.asg.arn
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.web_role.name
} 