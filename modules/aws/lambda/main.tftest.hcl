mock_provider "aws" {
  # ✅ Partition mocken
  override_data {
    target = data.aws_partition.this

    values = {
      partition                      = "aws"
      dns_suffix                     = "amazonaws.com"
      cloudfront_distribution_suffix = "cloudfront.amazonaws.com"
    }
  }

  # ✅ Region mocken (neu!)
  override_data {
    target = data.aws_region.current

    values = {
      name              = "eu-central-1"
      id                = "eu-central-1"
      partition         = "aws"
      name_by_alias     = "eu-central-1"
      is_outpost_region = false
    }
  }

  # ✅ Lambda Resource mocken
  override_resource {
    target = aws_lambda_function.this

    values = {
      function_name = "test-function-dev"
      arn           = "arn:aws:lambda:eu-central-1:123456789012:function:test-function-dev"
      invoke_url    = "https://lambda.eu-central-1.amazonaws.com/2015-03-31/functions/test-function-dev/invocations"
      role          = "arn:aws:iam::123456789012:role/test-function-dev-role"
      runtime       = "python3.11"
      timeout       = 30
      memory_size   = 256
      tracing_config = [
        { mode = "PassThrough" }
      ]
      environment_variables = {}
      s3_bucket             = null
      s3_key                = null
    }
  }

  # ✅ IAM Role mocken
  override_resource {
    target = aws_iam_role.this

    values = {
      name = "test-function-dev-role"
      arn  = "arn:aws:iam::123456789012:role/test-function-dev-role"
    }
  }
}

run "test_basic_lambda_creation" {
  variables {
    function_name           = "api-handler"
    environment             = "test"
    runtime                 = "python3.11"
    handler                 = "index.handler"
    vpc_subnet_ids          = []
    vpc_security_group_ids  = []
    source_archive_filename = "test.zip"
  }

  assert {
    condition     = resource.aws_lambda_function.this.function_name == "api-handler-test"
    error_message = "Function name must include environment suffix."
  }

  assert {
    condition     = resource.aws_lambda_function.this.runtime == "python3.11"
    error_message = "Runtime must match input."
  }
}

run "test_production_configuration" {
  variables {
    function_name           = "critical-job"
    environment             = "prod"
    runtime                 = "python3.11"
    handler                 = "main.handler"
    timeout                 = 300
    memory_size             = 1024
    enable_xray_tracing     = true
    vpc_subnet_ids          = []
    vpc_security_group_ids  = []
    source_archive_filename = "test.zip"
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
    condition     = resource.aws_lambda_function.this.tracing_config[0].mode == "Active"
    error_message = "X-Ray tracing must be enabled in production."
  }
}

run "test_xray_disabled_by_default" {
  variables {
    function_name           = "no-tracing-func"
    environment             = "test"
    vpc_subnet_ids          = []
    vpc_security_group_ids  = []
    source_archive_filename = "test.zip"
  }

  assert {
    condition     = resource.aws_lambda_function.this.tracing_config[0].mode == "PassThrough"
    error_message = "X-Ray should be disabled by default."
  }
}

run "test_iam_role_naming" {
  variables {
    function_name           = "iam-test-func"
    environment             = "staging"
    vpc_subnet_ids          = []
    vpc_security_group_ids  = []
    source_archive_filename = "test.zip"
  }

  assert {
    condition     = resource.aws_iam_role.this.name == "iam-test-func-staging-role"
    error_message = "IAM role must follow naming convention."
  }
}
