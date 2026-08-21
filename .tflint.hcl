config {
  format = "compact"
}

plugin "aws" {
  enabled    = true
  version    = "0.24.0"
  source     = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Globale Regeln
rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  variable {
    format = "snake_case"
  }
  resource {
    format = "snake_case"
  }
}

# AWS Lambda-spezifische Regeln
rule "aws_lambda_function_invalid_runtime" {
  enabled = true
}

rule "aws_lambda_function_memory_size" {
  enabled = true
}

rule "aws_lambda_function_timeout" {
  enabled = true
}

rule "aws_resource_missing_tags" {
  enabled = true
  tags = ["Name", "Environment", "ManagedBy"]
}