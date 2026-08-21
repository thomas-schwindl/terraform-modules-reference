variable "function_name" {
  description = "Base name for the Lambda function"
  type        = string
  validation {
    condition     = length(var.function_name) <= 50
    error_message = "Function name must be 50 characters or less."
  }
}

variable "environment" {
  description = "Environment tag (dev/staging/prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "runtime" {
  description = "Lambda runtime (e.g., python3.11, nodejs18.x, go1.x)"
  type        = string
  default     = "python3.11"
  validation {
    condition     = can(regex("^(python|nodejs|java|go|ruby|dotnet|provided)", var.runtime))
    error_message = "Runtime must be a supported Lambda runtime."
  }
}

variable "handler" {
  description = "Lambda handler function (e.g., index.handler)"
  type        = string
  default     = "index.handler"
}

variable "timeout" {
  description = "Timeout in seconds (max 900)"
  type        = number
  default     = 30
  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}

variable "memory_size" {
  description = "Memory size in MB (128-10240)"
  type        = number
  default     = 256
  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "Memory size must be between 128 and 10240 MB."
  }
}

variable "source_archive_filename" {
  description = "Local zip file path (mutually exclusive with S3 source)"
  type        = string
  default     = ""
}

variable "source_archive_s3_bucket" {
  description = "S3 bucket for deployment package"
  type        = string
  default     = null
}

variable "source_archive_s3_key" {
  description = "S3 key for deployment package"
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Lambda environment variables"
  type        = map(string)
  default     = {}
}

variable "enable_xray_tracing" {
  description = "Enable AWS X-Ray tracing"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
