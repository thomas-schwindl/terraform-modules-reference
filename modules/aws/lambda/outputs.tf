output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "invoke_url" {
  description = "Invoke URL for Lambda function"
  value       = "https://lambda.${data.aws_partition.this.region}.amazonaws.com/2015-03-31/functions/${aws_lambda_function.this.arn}/invocations"
}

output "function_iam_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.this.arn
}

output "function_iam_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.this.name
}
