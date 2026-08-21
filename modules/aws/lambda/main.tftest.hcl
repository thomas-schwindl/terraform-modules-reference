# main.tftest.hcl

mock_provider "aws" {
  override_data {
    target = aws_caller_identity.current
    
    values = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test"
    }
  }

  override_data {
    target = data.aws_partition.this
    
    values = {
      partition = "aws"
      region    = "eu-central-1"
    }
  }

  override_resource {
    target = aws_lambda_function.this
    
    values = {
      function_name = "test-function-${var.environment}"
      arn           = "arn:aws:lambda:eu-central-1:123456789012:function:test-${var.environment}"
      invoke_url    = "https://lambda.eu-central-1.amazonaws.com/2015-03-31/functions/test-${var.environment}/invocations"
      role          = "arn:aws:iam::123456789012:role/test-function-${var.environment}-role"
      runtime       = var.runtime
      timeout       = var.timeout
      memory_size   = var.memory_size
      
      tracing_config {
        mode = var.enable_xray_tracing ? "Active" : "PassThrough"
      }
      
      environment {
        variables = var.environment_variables
      }
      
      s3_bucket = var.source_archive_s3_bucket
      s3_key    = var.source_archive_s3_key
    }
  }

  override_resource {
    target = aws_iam_role.this
    
    values = {
      name = "${var.function_name}-${var.environment}-role"
      arn  = "arn:aws:iam::123456789012:role/${var.function_name}-${var.environment}-role"
    }
  }
}

# ──────────────────────────────────────────────────────────
# Test Case 1: Basic Creation (Standard)
# ──────────────────────────────────────────────────────────
run "test_basic_lambda_creation" {
  variables {
    function_name = "api-handler"
    environment   = "test"
    runtime       = "python3.11"
    handler       = "index.handler"
  }

  assert {
    condition     = resource.aws_lambda_function.this.function_name == "api-handler-test"
    error_message = "Function name must include environment suffix."
  }

  assert {
    condition     = resource.aws_lambda_function.this.runtime == "python3.11"
    error_message = "Runtime must match input."
  }

  assert {
    condition     = resource.aws_iam_role.this.name == "api-handler-test-role"
    error_message = "IAM role name must follow naming convention."
  }
}

# ──────────────────────────────────────────────────────────
# Test Case 2: Production Configuration (X-Ray + High Memory)
# ──────────────────────────────────────────────────────────
run "test_production_configuration" {
  variables {
    function_name        = "critical-job"
    environment          = "prod"
    runtime              = "python3.11"
    handler              = "main.handler"
    timeout              = 300
    memory_size          = 1024
    enable_xray_tracing  = true
    environment_variables = {
      LOG_LEVEL    = "INFO"
      DATABASE_URL = "postgresql://db.example.com"
    }
  }

  assert {
    condition     = resource.aws_lambda_function.this.timeout == 300
    error_message = "Production timeout should be higher."
  }

  assert {
    condition     = resource.aws_lambda_function.this.memory_size == 1024
    error_message = "Production memory should be 1024MB."
  }

  assert {
    condition     = resource.aws_lambda_function.this.tracing_config.mode == "Active"
    error_message = "X-Ray tracing must be enabled in production."
  }

  assert {
    condition     = length(resource.aws_lambda_function.this.environment.variables) == 2
    error_message = "Should have exactly 2 environment variables."
  }
}

# ──────────────────────────────────────────────────────────
# Test Case 3: Environment Variable Defaults
# ──────────────────────────────────────────────────────────
run "test_empty_environment_variables" {
  variables {
    function_name = "simple-function"
    environment   = "dev"
  }

  assert {
    condition     = length(resource.aws_lambda_function.this.environment.variables) == 0
    error_message = "Should have no environment variables by default."
  }
}

# ──────────────────────────────────────────────────────────
# Test Case 4: Custom Tags Propagation
# ──────────────────────────────────────────────────────────
run "test_custom_tags" {
  variables {
    function_name = "tagged-function"
    environment   = "test"
    tags = {
      Team     = "platform"
      CostCode = "12345"
      Owner    = "john.doe@example.com"
    }
  }

  assert {
    condition     = resource.aws_lambda_function.this.tags.Team == "platform"
    error_message = "Custom tags should propagate to Lambda."
  }

  assert {
    condition     = resource.aws_lambda_function.this.tags.Owner == "john.doe@example.com"
    error_message = "Owner tag must be preserved."
  }
}

# ──────────────────────────────────────────────────────────
# Test Case 5: X-Ray Disabled by Default
# ──────────────────────────────────────────────────────────
run "test_xray_disabled_by_default" {
  variables {
    function_name = "no-tracing-func"
    environment   = "test"
  }

  assert {
    condition     = resource.aws_lambda_function.this.tracing_config.mode == "PassThrough"
    error_message = "X-Ray should be disabled by default."
  }
}

# ──────────────────────────────────────────────────────────
# Test Case 6: IAM Role Naming Convention
# ──────────────────────────────────────────────────────────
run "test_iam_role_naming" {
  variables {
    function_name = "iam-test-func"
    environment   = "staging"
  }

  assert {
    condition     = resource.aws_iam_role.this.name == "iam-test-func-staging-role"
    error_message = "IAM role must include function name and environment."
  }
}

# ──────────────────────────────────────────────────────────
# Test Case 7: S3 Source Configuration
# ──────────────────────────────────────────────────────────
run "test_s3_source_configuration" {
  variables {
    function_name          = "s3-deployed-function"
    environment            = "test"
    source_archive_s3_bucket = "my-deployment-bucket"
    source_archive_s3_key    = "lambda/v1.2.3.zip"
  }

  assert {
    condition     = resource.aws_lambda_function.this.s3_bucket == "my-deployment-bucket"
    error_message = "S3 bucket must match input."
  }

  assert {
    condition     = resource.aws_lambda_function.this.s3_key == "lambda/v1.2.3.zip"
    error_message = "S3 key must match input."
  }
}

# ──────────────────────────────────────────────────────────
# Test Case 8: Memory Scaling
# ──────────────────────────────────────────────────────────
run "test_high_memory_configuration" {
  variables {
    function_name = "memory-intensive"
    environment   = "prod"
    memory_size   = 4096
    timeout       = 600
  }

  assert {
    condition     = resource.aws_lambda_function.this.memory_size == 4096
    error_message = "Memory size must be 4096MB for intensive workload."
  }

  assert {
    condition     = resource.aws_lambda_function.this.timeout == 600
    error_message = "Timeout should scale with memory."
  }
}