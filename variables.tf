variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "kDj3jXr5zJjskYavXmGX7H"
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
  default     = "bH3F&NUA%TYexnaMxGDws$"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "fresco"
}

variable "jwt_secret" {
  description = "Secret key used to sign JWT tokens"
  type        = string
  sensitive   = true
  default     = "your-very-secure-jwt-secret"
}

variable "jwt_issuer" {
  description = "Issuer for JWT tokens"
  type        = string
  default     = "my-local-test-app"
}
